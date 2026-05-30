// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
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
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  html.AudioElement? _audio;
  String? _audioUrl;
  Completer<void>? _playbackCompleter;
  final List<html.Blob> _chunks = [];

  bool get isSupported => html.window.navigator.mediaDevices != null;

  Future<void> startRecording() async {
    if (!isSupported) {
      throw UnsupportedError('Voice recording is not supported in this browser.');
    }

    _chunks.clear();
    final stream = await html.window.navigator.mediaDevices!.getUserMedia({
      'audio': true,
    });
    final mimeType = _selectMimeType();
    final options = mimeType.isEmpty ? null : {'mimeType': mimeType};
    final recorder = html.MediaRecorder(stream, options);

    recorder.addEventListener('dataavailable', (html.Event event) {
      final data = (event as dynamic).data as html.Blob?;
      if (data != null && data.size > 0) {
        _chunks.add(data);
      }
    });

    _stream = stream;
    _recorder = recorder;
    recorder.start();
  }

  Future<RecordedAudio?> stopRecording() async {
    final recorder = _recorder;
    if (recorder == null) return null;

    final stopped = Completer<void>();
    recorder.addEventListener('stop', (html.Event event) {
      if (!stopped.isCompleted) stopped.complete();
    });

    recorder.stop();
    await stopped.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    _stopStream();

    if (_chunks.isEmpty) return null;
    final recorderMimeType = recorder.mimeType ?? '';
    final mimeType = recorderMimeType.isNotEmpty ? recorderMimeType : 'audio/webm';
    final blob = html.Blob(_chunks, mimeType);
    final bytes = await _readBlob(blob);
    _chunks.clear();
    _recorder = null;

    if (bytes.isEmpty) return null;
    final extension = mimeType.contains('ogg') ? 'ogg' : 'webm';
    return RecordedAudio(
      bytes: bytes,
      mimeType: mimeType,
      fileName: 'voice-message.$extension',
    );
  }

  Future<void> playAudio(Uint8List bytes, String mimeType) async {
    stopPlayback();
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(url);
    final completed = Completer<void>();
    _playbackCompleter = completed;
    _audioUrl = url;
    _audio = audio;

    audio.onEnded.listen((_) {
      stopPlayback();
      if (!completed.isCompleted) completed.complete();
    });
    audio.onError.listen((_) {
      stopPlayback();
      if (!completed.isCompleted) completed.completeError('Audio playback failed');
    });
    await audio.play();
    await completed.future;
  }

  void stopPlayback() {
    _audio?.pause();
    _audio = null;
    final url = _audioUrl;
    if (url != null) {
      html.Url.revokeObjectUrl(url);
    }
    _audioUrl = null;
    final completed = _playbackCompleter;
    if (completed != null && !completed.isCompleted) {
      completed.complete();
    }
    _playbackCompleter = null;
  }

  void dispose() {
    _recorder?.stop();
    _stopStream();
    stopPlayback();
  }

  void _stopStream() {
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;
  }

  String _selectMimeType() {
    const types = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/ogg;codecs=opus',
      'audio/ogg',
    ];
    for (final type in types) {
      if (html.MediaRecorder.isTypeSupported(type)) return type;
    }
    return '';
  }

  Future<Uint8List> _readBlob(html.Blob blob) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;
    final result = reader.result;
    if (result is ByteBuffer) return Uint8List.view(result);
    if (result is Uint8List) return result;
    return Uint8List(0);
  }
}
