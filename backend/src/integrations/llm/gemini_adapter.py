import httpx

from src.config.settings import get_settings


settings = get_settings()


def _build_system_instruction(profile_context: dict[str, str]) -> str:
    profile_lines = []
    for key, value in profile_context.items():
        if value:
            profile_lines.append(f"- {key}: {value}")

    profile_block = "\n".join(profile_lines) if profile_lines else "- profile: not provided"
    return (
        "You are Farmly, an agricultural assistant for Ethiopian smallholder farmers.\n"
        "Give practical, clear, and simple advice suitable for the farmer's context.\n"
        "Prefer agriculture-focused answers. If off-topic, gently redirect to farming help.\n"
        "Return ONLY plain text (no JSON, no YAML, no markdown such as headings, bullets, or code blocks).\n"
        "Do NOT use lists or numbered steps—use short sentences separated by line breaks.\n"
        "Keep the answer short and easy to understand for non-technical farmers. Use 2-6 short lines and avoid complex words.\n\n"
        "Farmer profile context:\n"
        f"{profile_block}"
    )


def _build_contents(recent_messages: list[dict[str, str]], latest_user_message: str) -> list[dict]:
    contents: list[dict] = []
    for msg in recent_messages:
        role = "user" if msg.get("sender") == "user" else "model"
        text = (msg.get("content") or "").strip()
        if not text:
            continue
        contents.append({"role": role, "parts": [{"text": text}]})

    contents.append({"role": "user", "parts": [{"text": latest_user_message.strip()}]})
    return contents


def generate_reply(
    *,
    latest_user_message: str,
    recent_messages: list[dict[str, str]],
    profile_context: dict[str, str],
) -> str:
    if not settings.gemini_api_key:
        raise RuntimeError("GEMINI_API_KEY is not configured")
    if not settings.gemini_model:
        raise RuntimeError("GEMINI_MODEL is not configured")

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{settings.gemini_model}:generateContent"
    )

    payload = {
        "system_instruction": {
            "parts": [{"text": _build_system_instruction(profile_context)}],
        },
        "contents": _build_contents(recent_messages, latest_user_message),
        "generationConfig": {
            "temperature": 0.4,
        },
    }

    with httpx.Client(timeout=float(settings.gemini_timeout_seconds)) as client:
        response = client.post(
            url,
            params={"key": settings.gemini_api_key},
            json=payload,
        )

    if response.status_code >= 400:
        raise RuntimeError(f"Gemini provider error ({response.status_code}): {response.text}")

    data = response.json()
    candidates = data.get("candidates") or []
    if not candidates:
        raise RuntimeError("Gemini returned no candidates")

    parts = ((candidates[0].get("content") or {}).get("parts")) or []
    text = "".join([(p.get("text") or "") for p in parts]).strip()
    if not text:
        raise RuntimeError("Gemini returned empty response")

    # Basic cleanup: remove common markdown bullets/headers and trim
    def _clean_text(t: str) -> str:
        # remove markdown headers and code fences
        lines = t.splitlines()
        cleaned_lines = []
        for line in lines:
            s = line.strip()
            # drop markdown fences
            if s.startswith('```'):
                continue
            # remove leading list markers
            if s.startswith(('- ', '* ', '+ ', '• ', '-\t')):
                s = s.lstrip('-*+• \t')
            # remove heading markers
            while s.startswith('#'):
                s = s.lstrip('#').strip()
            cleaned_lines.append(s)
        cleaned = '\n'.join([ln for ln in cleaned_lines if ln])
        return cleaned.strip()

    return _clean_text(text)
