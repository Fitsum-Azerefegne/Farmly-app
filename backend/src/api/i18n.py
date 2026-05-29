"""Simple i18n helper used by API routes.

Provides a `t(key, lang='en')` function that returns an English translation
for a small set of keys used across the backend. Missing keys fall back to the
key itself so the server never crashes due to missing translations.
"""
from typing import Dict

_EN: Dict[str, str] = {
    "current_password_incorrect": "Current password is incorrect",
    "phone_change_otp_sent": "Phone change OTP sent",
    "phone_in_use": "Phone number already in use",
    "otp_expired": "OTP expired",
    "max_attempts_exceeded": "Maximum OTP attempts exceeded",
    "otp_invalid": "Invalid OTP",
    "phone_changed_success": "Phone number changed successfully",
}


def t(key: str, lang: str = "en") -> str:
    """Translate `key` to the requested `lang`. Currently only English is
    supported; unknown keys return the key itself.
    """
    if not key:
        return ""
    if lang and lang != "en":
        # future: load other languages
        pass
    return _EN.get(key, key)
