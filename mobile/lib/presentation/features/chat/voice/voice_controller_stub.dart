import 'dart:typed_data';


class RecordedAudio {
  final Uint8List bytes;
  final String mimeType;
  final String fileName;

  const RecordedAudio({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });
}


class VoiceController {
  bool get isSupported => false;

  Future<void> startRecording() async {
    throw UnsupportedError('Voice recording is not supported on this platform.');
  }

  Future<RecordedAudio?> stopRecording() async {
    throw UnsupportedError('Voice recording is not supported on this platform.');
  }

  Future<void> playAudio(Uint8List bytes, String mimeType) async {
    throw UnsupportedError('Voice playback is not supported on this platform.');
  }

  void stopPlayback() {}

  void dispose() {}
}
