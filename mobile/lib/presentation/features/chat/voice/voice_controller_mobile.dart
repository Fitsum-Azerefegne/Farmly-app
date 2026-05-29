import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _playbackSubscription;
  Completer<void>? _playbackCompleter;
  String? _recordingPath;

  bool get isSupported => true;

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission is required.');
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${tempDir.path}${Platform.pathSeparator}$fileName';
    _recordingPath = path;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
  }

  Future<RecordedAudio?> stopRecording() async {
    final path = await _recorder.stop();
    final resolvedPath = path ?? _recordingPath;
    _recordingPath = null;

    if (resolvedPath == null) return null;
    final file = File(resolvedPath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    await file.delete().catchError((_) => file);
    if (bytes.isEmpty) return null;

    return RecordedAudio(
      bytes: bytes,
      mimeType: 'audio/mp4',
      fileName: 'voice-message.m4a',
    );
  }

  Future<void> playAudio(Uint8List bytes, String mimeType) async {
    stopPlayback();

    final completed = Completer<void>();
    _playbackCompleter = completed;
    _playbackSubscription = _player.onPlayerComplete.listen((_) {
      if (!completed.isCompleted) completed.complete();
    });

    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(BytesSource(bytes));
    await completed.future;
  }

  void stopPlayback() {
    _playbackSubscription?.cancel();
    _playbackSubscription = null;
    _player.stop();

    final completed = _playbackCompleter;
    if (completed != null && !completed.isCompleted) {
      completed.complete();
    }
    _playbackCompleter = null;
  }

  void dispose() {
    _recorder.dispose();
    stopPlayback();
    _player.dispose();
  }
}
