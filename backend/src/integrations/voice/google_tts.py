from src.config.settings import get_settings
from src.integrations.voice.google_credentials import get_google_credentials


def _load_texttospeech():
    from google.cloud import texttospeech

    return texttospeech


def _load_client_options():
    from google.api_core.client_options import ClientOptions

    return ClientOptions


def _audio_encoding(texttospeech, encoding_name: str):
    normalized = encoding_name.upper()
    try:
        return getattr(texttospeech.AudioEncoding, normalized)
    except AttributeError as exc:
        raise RuntimeError(f"Unsupported Google TTS audio encoding: {normalized}") from exc


def synthesize_speech(text: str) -> bytes:
    settings = get_settings()
    texttospeech = _load_texttospeech()
    audio_encoding = _audio_encoding(texttospeech, settings.google_tts_audio_encoding)
    client = texttospeech.TextToSpeechClient(credentials=get_google_credentials())

    voice_kwargs = {"language_code": settings.google_tts_language_code}
    if settings.google_tts_voice_name:
        voice_kwargs["name"] = settings.google_tts_voice_name

    response = client.synthesize_speech(
        input=texttospeech.SynthesisInput(text=text),
        voice=texttospeech.VoiceSelectionParams(**voice_kwargs),
        audio_config=texttospeech.AudioConfig(
            audio_encoding=audio_encoding,
            speaking_rate=settings.google_tts_speaking_rate,
        ),
    )
    return bytes(response.audio_content)
