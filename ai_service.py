"""AI service for chat functionality using OpenAI SDK (compatible with Zhipu AI GLM-4)."""

import os
from typing import Any

import streamlit as st
from openai import OpenAI

# Model configuration
# Zhipu AI GLM-4 models accessible via OpenAI-compatible API
DEFAULT_MODEL = "glm-4.7"
DEFAULT_TEMPERATURE = 0.7
MAX_TOKENS = 2048

# Zhipu AI base URL for OpenAI SDK compatibility
ZHIPUAI_BASE_URL = "https://api.z.ai/api/coding/paas/v4"


def get_api_key() -> str:
    """Get Zhipu AI API key from Streamlit secrets or environment variable."""
    # Try Streamlit secrets first (recommended for deployment)
    if hasattr(st, "secrets") and "zhipuai" in st.secrets:
        return st.secrets.zhipuai.api_key

    # Fallback to environment variable
    if "ZHIPUAI_API_KEY" in os.environ:
        return os.environ["ZHIPUAI_API_KEY"]

    raise ValueError(
        "Zhipu AI API key not found. Please set it in Streamlit secrets "
        "(.streamlit/secrets.toml) or ZHIPUAI_API_KEY environment variable."
    )


def build_system_prompt(problem: Any) -> str:
    """Build system prompt with problem context for the AI coach."""
    metadata = problem.metadata

    # Build context from problem metadata
    context_parts = [
        "# Role",
        "You are an expert technical coach helping a learner work through a system design/incident problem.",
        "",
        "# Current Problem",
    ]

    if "name" in metadata:
        context_parts.append(f"**Problem**: {metadata['name']}")

    for key in ["category", "difficulty", "time"]:
        if key in metadata:
            context_parts.append(f"**{key.title()}**: {metadata[key]}")

    if "concepts" in metadata:
        concepts = metadata["concepts"]
        if isinstance(concepts, list):
            context_parts.append(f"**Concepts**: {', '.join(concepts)}")

    # Add problem content (truncated if too long)
    context_parts.extend(
        [
            "",
            "# Problem Description",
            problem.content[:2000] + "..."
            if len(problem.content) > 2000
            else problem.content,
            "",
            "# Coaching Approach",
            "- Ask guiding questions to help the learner think through the problem",
            "- Provide hints without giving away the full solution",
            "- Encourage the learner to explain their reasoning",
            "- If they're truly stuck, suggest they look at the step hints",
            "- Be concise and friendly",
            "",
            "Remember: The goal is learning, not just solving. Guide, don't tell.",
        ]
    )

    return "\n".join(context_parts)


def get_ai_response(
    messages: list[dict[str, str]],
    problem: Any,
    model: str = DEFAULT_MODEL,
    temperature: float = DEFAULT_TEMPERATURE,
) -> str:
    """
    Get AI response using OpenAI SDK with Zhipu AI GLM-4.

    Args:
        messages: Chat history with 'role' and 'content' keys
        problem: Current ProblemDetail object for context
        model: Model name (default: glm-4)
        temperature: Response randomness (0-1)

    Returns:
        AI response text
    """
    try:
        api_key = get_api_key()

        # Initialize OpenAI client with Zhipu AI base URL
        client = OpenAI(
            api_key=api_key,
            base_url=ZHIPUAI_BASE_URL,
        )

        # Build messages for API call
        api_messages = [{"role": "system", "content": build_system_prompt(problem)}]

        # Add chat history
        for msg in messages:
            api_messages.append({"role": msg["role"], "content": msg["content"]})

        response = client.chat.completions.create(
            model=model,
            messages=api_messages,
            temperature=temperature,
            max_tokens=MAX_TOKENS,
        )

        return response.choices[0].message.content

    except Exception as e:
        return f"**Error getting AI response**: {str(e)}\n\nPlease check your API key configuration."


def clear_chat_history(problem_id: str):
    """Clear chat history for a specific problem."""
    if "chat_messages" in st.session_state:
        if problem_id in st.session_state.chat_messages:
            del st.session_state.chat_messages[problem_id]
