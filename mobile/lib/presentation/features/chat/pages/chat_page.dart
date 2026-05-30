// ignore_for_file: prefer_const_constructors, prefer_const_declarations, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api.dart';
import '../../../shared/app_button.dart';

import '../../../../core/toast.dart';
import '../../profile/profile_sidebar.dart';
import '../voice/voice_controller.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class _Session {
  final String id;
  String title;
  _Session({required this.id, required this.title});
  factory _Session.fromJson(Map<String, dynamic> j) =>
      _Session(id: j['session_id'], title: j['title'] ?? 'New Chat');
}

class _Msg {
  final String id;
  final String sender;
  final String content;
  final bool optimistic;
  final DateTime? createdAt;
  _Msg({
    required this.id,
    required this.sender,
    required this.content,
    this.optimistic = false,
    this.createdAt,
  });
  factory _Msg.fromJson(Map<String, dynamic> j) {
    DateTime? parsed;
    final v =
        j['created_at'] ?? j['createdAt'] ?? j['timestamp'] ?? j['created'];
    if (v is String) {
      try {
        parsed = DateTime.tryParse(v)?.toLocal();
      } catch (_) {
        parsed = null;
      }
    } else if (v is int) {
      try {
        parsed = DateTime.fromMillisecondsSinceEpoch(v).toLocal();
      } catch (_) {
        parsed = null;
      }
    }
    return _Msg(
      id: j['message_id'] ?? j['id'] ?? '',
      sender: j['sender'] ?? 'assistant',
      content: j['content'] ?? '',
      optimistic: j['optimistic'] ?? false,
      createdAt: parsed,
    );
  }
}

// Small polished quick-action button used on the welcome screen.
class _QuickActionButton extends StatefulWidget {
  final double width;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionButton(
      {required this.width,
      required this.icon,
      required this.label,
      this.onTap});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hover = false;

  void _setHover(bool v) => setState(() => _hover = v);

  @override
  Widget build(BuildContext context) {
    final bg = _hover ? Colors.white : Colors.white;
    final shadow = _hover
        ? const [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ]
        : const [
            BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 4,
                offset: Offset(0, 2))
          ];

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: shadow,
              border: Border.all(
                  color: Colors.grey.shade200, width: _hover ? 1.2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(27, 138, 62, 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class ChatPage extends StatefulWidget {
  final String accessToken;
  const ChatPage({super.key, required this.accessToken});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _bases = apiBases;

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _renameCtrl = TextEditingController();
  final _voiceCtrl = VoiceController();

  List<_Session> _sessions = [];
  _Session? _active;
  List<_Msg> _messages = [];
  bool _loadingSessions = false;
  bool _loadingMessages = false;
  bool _sending = false;
  bool _typing = false;
  bool _recording = false;
  bool _voiceBusy = false;
  String? _speakingMessageId;
  XFile? _pickedImage;
  bool _sidebarOpen = true;
  bool _profileOpen = false;

  String _capitalizeLabel(String s) {
    // Normalize spacing and capitalization: title case for important words
    final parts = s.trim().split(RegExp(r'\s+'));
    return parts
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _renameCtrl.dispose();
    _voiceCtrl.dispose();
    super.dispose();
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${widget.accessToken}',
        'Accept': 'application/json',
      };

  Future<http.Response?> _get(String path) async {
    for (final base in _bases) {
      try {
        return await http.get(Uri.parse('$base$path'), headers: _headers);
      } catch (_) {}
    }
    return null;
  }

  Future<http.Response?> _post(String path, Map<String, dynamic> body) async {
    for (final base in _bases) {
      try {
        return await http.post(
          Uri.parse('$base$path'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } catch (_) {}
    }
    return null;
  }

  Future<http.Response?> _patch(String path, Map<String, dynamic> body) async {
    for (final base in _bases) {
      try {
        return await http.patch(
          Uri.parse('$base$path'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } catch (_) {}
    }
    return null;
  }

  Future<http.Response?> _delete(String path) async {
    for (final base in _bases) {
      try {
        return await http.delete(Uri.parse('$base$path'), headers: _headers);
      } catch (_) {}
    }
    return null;
  }

  // ── Sessions ──

  Future<void> _fetchSessions() async {
    setState(() => _loadingSessions = true);
    final r = await _get('/api/chat/sessions?limit=50');
    if (!mounted) return;
    if (r != null && r.statusCode == 200) {
      final list = (jsonDecode(r.body) as List)
          .map((e) => _Session.fromJson(e))
          .toList();
      setState(() {
        _sessions = list;
        _loadingSessions = false;
      });
      if (list.isNotEmpty && _active == null) {
        _selectSession(list.first);
      } else if (list.isEmpty && _active == null) {
        await _createSession();
      }
    } else {
      setState(() => _loadingSessions = false);
      if (kDebugMode) {
        print('Failed to load sessions: ${r?.statusCode} ${r?.body}');
      }
      if (mounted) {
        // show a user-facing toast so they know something went wrong
        Toast.show(context, 'Failed to load chat sessions');
      }
    }
  }

  Future<_Session?> _createSession() async {
    final r = await _post('/api/chat/sessions', {'title': 'New Chat'});
    if (!mounted) return null;
    if (r != null && r.statusCode == 201) {
      final s = _Session.fromJson(jsonDecode(r.body));
      setState(() => _sessions.insert(0, s));
      _selectSession(s);
      return s;
    }

    if (mounted) {
      Toast.show(context, 'Could not create chat session');
    }
    return null;
  }

  Future<void> _renameSession(_Session s, String title) async {
    final old = s.title;
    setState(() => s.title = title);
    final r = await _patch('/api/chat/sessions/${s.id}', {'title': title});
    if (!mounted) return;
    if (r == null || r.statusCode != 200) setState(() => s.title = old);
  }

  Future<void> _deleteSession(_Session s) async {
    final wasActive = _active?.id == s.id;
    final remaining = _sessions.where((x) => x.id != s.id).toList();
    final nextActive =
        wasActive ? (remaining.isNotEmpty ? remaining.first : null) : _active;

    setState(() {
      _sessions = remaining;
      if (wasActive) {
        _active = nextActive;
        _messages = [];
      }
    });

    if (wasActive && nextActive != null) _fetchMessages(nextActive);
    await _delete('/api/chat/sessions/${s.id}');
  }

  void _selectSession(_Session s) {
    if (_active?.id == s.id) return;
    setState(() {
      _active = s;
      _messages = [];
    });
    _fetchMessages(s);
  }

  // ── Messages ──

  Future<void> _fetchMessages(_Session s) async {
    setState(() => _loadingMessages = true);
    final r = await _get('/api/chat/sessions/${s.id}/messages?limit=100');
    if (!mounted) return;
    // user may have switched session while this was loading
    if (_active?.id != s.id) return;
    if (r != null && r.statusCode == 200) {
      final list =
          (jsonDecode(r.body) as List).map((e) => _Msg.fromJson(e)).toList();
      setState(() {
        _messages = list;
        _loadingMessages = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _loadingMessages = false);
      if (kDebugMode)
        print(
            'Failed to load messages for ${s.id}: ${r?.statusCode} ${r?.body}');
      if (mounted) Toast.show(context, 'Failed to load messages');
    }
  }

  Future<void> _send({bool speakResponse = false}) async {
    final text = _msgCtrl.text.trim();
    final img = _pickedImage;
    if (text.isEmpty && img == null) return;
    if (_sending) return;
    if (_active == null || _active!.id.startsWith('local_')) {
      final created = await _createSession();
      if (created == null) return;
    }

    final optimisticId = 'opt_${DateTime.now().millisecondsSinceEpoch}';
    final displayText = text.isNotEmpty ? text : '📷 Image';

    setState(() {
      _messages.add(_Msg(
        id: optimisticId,
        sender: 'user',
        content: displayText,
        optimistic: true,
        createdAt: DateTime.now(),
      ));
      _sending = true;
      _typing = true;
      _msgCtrl.clear();
      _pickedImage = null;
    });

    http.Response? r;

    if (img == null) {
      for (final base in _bases) {
        try {
          r = await http.post(
            Uri.parse('$base/api/chat/sessions/${_active!.id}/messages'),
            headers: _headers,
            body: {'message': text},
          );
          break;
        } catch (_) {}
      }
    } else {
      for (final base in _bases) {
        try {
          final req = http.MultipartRequest('POST',
              Uri.parse('$base/api/chat/sessions/${_active!.id}/messages'));
          req.headers.addAll(_headers);
          req.fields['message'] = text;
          final bytes = await img.readAsBytes();
          req.files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: img.name,
            contentType: _imageMediaType(img),
          ));
          final streamed = await req.send();
          r = await http.Response.fromStream(streamed);
          break;
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _sending = false;
      _typing = false;
      _messages.removeWhere((m) => m.id == optimisticId);
    });

    if (r != null && r.statusCode == 200) {
      try {
        final data = jsonDecode(r.body);
        _Msg? assistantMessage;
        setState(() {
          if (data['user_message'] != null) {
            _messages.add(_Msg.fromJson(data['user_message']));
          }
          if (data['assistant_message'] != null) {
            assistantMessage = _Msg.fromJson(data['assistant_message']);
            _messages.add(assistantMessage!);
          }
          // update session title if backend generated one
          if (data['session_title'] != null && _active != null) {
            final newTitle = data['session_title'] as String;
            if (newTitle.trim().isNotEmpty && newTitle != _active!.title) {
              _active!.title = newTitle;
              final idx = _sessions.indexWhere((s) => s.id == _active!.id);
              if (idx != -1) _sessions[idx].title = newTitle;
            }
          }
        });
        _scrollToBottom();
        if (speakResponse && assistantMessage != null) {
          await _speakMessage(assistantMessage!);
        }
      } catch (_) {
        Toast.show(context, 'Invalid response from server');
      }
    } else {
      final err = r != null ? r.body : 'No response from server';
      if (kDebugMode) {
        Toast.show(context, 'Send failed: $err');
      } else {
        Toast.show(context, 'Send failed');
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_voiceBusy || _sending) return;
    if (!_voiceCtrl.isSupported) {
      Toast.show(context, 'Voice recording is not supported in this browser');
      return;
    }

    if (!_recording) {
      try {
        await _voiceCtrl.startRecording();
        if (mounted) setState(() => _recording = true);
      } catch (e) {
        if (mounted) Toast.show(context, 'Could not start recording: $e');
      }
      return;
    }

    setState(() {
      _recording = false;
      _voiceBusy = true;
    });
    try {
      final audio = await _voiceCtrl.stopRecording();
      if (audio == null || audio.bytes.isEmpty) {
        if (mounted) Toast.show(context, 'No audio was recorded');
        return;
      }
      await _sendVoice(audio);
    } catch (e) {
      if (mounted) Toast.show(context, 'Voice message failed: $e');
    } finally {
      if (mounted) setState(() => _voiceBusy = false);
    }
  }

  Future<void> _sendVoice(RecordedAudio audio) async {
    http.Response? r;
    for (final base in _bases) {
      try {
        final req = http.MultipartRequest(
          'POST',
          Uri.parse('$base/api/voice/transcribe'),
        );
        req.headers.addAll(_headers);
        req.files.add(http.MultipartFile.fromBytes(
          'audio',
          audio.bytes,
          filename: audio.fileName,
          contentType: _mediaType(audio.mimeType),
        ));
        final streamed = await req.send();
        r = await http.Response.fromStream(streamed);
        break;
      } catch (_) {}
    }

    if (!mounted) return;
    if (r == null) {
      Toast.show(context, 'Unable to reach voice service');
      return;
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      Toast.show(context, _extractError(r, 'Voice transcription failed'));
      return;
    }

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final transcript = (data['transcript'] as String? ?? '').trim();
    if (transcript.isEmpty) {
      Toast.show(context, 'No speech was detected');
      return;
    }
    _msgCtrl.text = transcript;
    await _send(speakResponse: true);
  }

  Future<void> _speakMessage(_Msg msg) async {
    if (msg.sender == 'user' || msg.content.trim().isEmpty) return;
    if (_speakingMessageId == msg.id) {
      _voiceCtrl.stopPlayback();
      setState(() => _speakingMessageId = null);
      return;
    }

    setState(() => _speakingMessageId = msg.id);
    try {
      http.Response? r;
      for (final base in _bases) {
        try {
          r = await http.post(
            Uri.parse('$base/api/voice/synthesize'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': msg.content}),
          );
          break;
        } catch (_) {}
      }
      if (!mounted) return;
      if (r == null) {
        Toast.show(context, 'Unable to reach voice service');
        return;
      }
      if (r.statusCode < 200 || r.statusCode >= 300) {
        Toast.show(context, _extractError(r, 'Voice playback failed'));
        return;
      }
      await _voiceCtrl.playAudio(r.bodyBytes, 'audio/mpeg');
    } catch (e) {
      if (mounted) Toast.show(context, 'Voice playback failed: $e');
    } finally {
      if (mounted && _speakingMessageId == msg.id) {
        setState(() => _speakingMessageId = null);
      }
    }
  }

  MediaType? _mediaType(String value) {
    final parts = value.split(';').first.split('/');
    if (parts.length != 2) return null;
    return MediaType(parts[0], parts[1]);
  }

  MediaType _imageMediaType(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) {
      return _mediaType(mimeType) ?? MediaType('image', 'jpeg');
    }

    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  String _extractError(http.Response resp, String fallback) {
    try {
      final data = jsonDecode(resp.body);
      final detail = data['detail'];
      if (detail is String) return detail;
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null && mounted) setState(() => _pickedImage = img);
  }

  void _showRenameDialog(_Session s) {
    _renameCtrl.text = s.title;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename chat'),
        content: TextField(
          controller: _renameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Session title'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final t = _renameCtrl.text.trim();
              if (t.isNotEmpty) _renameSession(s, t);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(_Session s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text('Delete "${s.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(s);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Row(
            children: [
              if (isWide || _sidebarOpen) _buildSidebar(isWide),
              Expanded(child: _buildChat(isWide)),
            ],
          ),
          // overlay when profile open
          if (_profileOpen)
            GestureDetector(
              onTap: () => setState(() => _profileOpen = false),
              child: Container(color: Colors.black38),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _profileOpen
                ? 0
                : -(MediaQuery.of(context).size.width < 600
                    ? MediaQuery.of(context).size.width * 0.9
                    : 380.0),
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width < 600
                  ? MediaQuery.of(context).size.width * 0.9
                  : 380.0,
              child: ProfileSidebar(
                accessToken: widget.accessToken,
                onClose: () => setState(() => _profileOpen = false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isWide) {
    return Container(
      width: 260,
      color: const Color(0xFFEFF8EE),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const SizedBox.shrink(),
                  const SizedBox(width: 8),
                  const SizedBox.shrink(),
                  if (!isWide)
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.muted, size: 20),
                      onPressed: () => setState(() => _sidebarOpen = false),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  onPressed: _createSession,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('New Chat', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: Colors.black12, height: 16),
            Expanded(
              child: _loadingSessions
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : _sessions.isEmpty
                      ? const Center(
                          child: Text('No chats yet',
                              style: TextStyle(
                                  color: AppColors.mutedLight, fontSize: 13)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _sessions.length,
                          itemBuilder: (_, i) =>
                              _buildSessionTile(_sessions[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(_Session s) {
    final isActive = _active?.id == s.id;
    return GestureDetector(
      onTap: () => _selectSession(s),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline,
                color: AppColors.muted, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? AppColors.darkPrimary : AppColors.muted,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon:
                  const Icon(Icons.more_vert, color: AppColors.muted, size: 16),
              color: Colors.white,
              onSelected: (v) {
                if (v == 'rename') _showRenameDialog(s);
                if (v == 'delete') _confirmDelete(s);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(bool isWide) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 8,
            left: 8,
            right: 16,
          ),
          child: Row(
            children: [
              if (!isWide)
                IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.primary),
                  onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
                ),
              const SizedBox.shrink(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (_active?.title != null && _active!.title != 'New Chat')
                      ? _active!.title
                      : 'Farmly Assistant',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.darkPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_active != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.muted),
                  onPressed: () => _showRenameDialog(_active!),
                ),
              IconButton(
                icon:
                    const Icon(Icons.person, size: 18, color: AppColors.muted),
                onPressed: () => setState(() => _profileOpen = true),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _active == null
              ? _buildEmptyState()
              : _loadingMessages
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : (_messages.isEmpty && !_typing)
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _messages.length + (_typing ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (_typing && i == _messages.length) {
                              return _buildTypingBubble();
                            }
                            return _buildMessageBubble(_messages[i]);
                          },
                        ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildEmptyState() {
    const actions = [
      {
        'icon': Icons.agriculture,
        'label': 'Recommend a crop',
        'text': 'Recommend crop for my farm.'
      },
      {
        'icon': Icons.healing,
        'label': 'Diagonise my plant',
        'text': 'Diagnose plant disease from symptoms.'
      },
      {
        'icon': Icons.cloud,
        'label': 'Check the weather',
        'text': 'Show weather forecast.'
      },
      {
        'icon': Icons.local_florist,
        'label': 'Fertilizer advice',
        'text': 'Recommend fertilizer for my crops.'
      },
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final isNarrow = width < 600;
      // tablet breakpoint (not needed here)

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(27, 138, 62, 0.08),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.eco, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text('Welcome to Farmly',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkPrimary)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Your farming assistant — diagnose, advise, and plan with confidence.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 20),
              Builder(builder: (ctx) {
                final containerPadding =
                    isNarrow ? 12.0 : (width >= 900 ? 36.0 : 20.0);
                final spacing = 12.0;
                // desired max button width
                const maxBtnW = 320.0;
                // compute button width: full width on narrow, otherwise two-column capped
                final btnWidth = isNarrow
                    ? (width - 48)
                    : math.min(
                        (width - containerPadding * 2 - spacing) / 2, maxBtnW);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: containerPadding),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: spacing,
                    runSpacing: 12,
                    children: actions.map((a) {
                      final label = (a['label'] as String).replaceAll('_', ' ');
                      return _QuickActionButton(
                        width: btnWidth,
                        icon: a['icon'] as IconData,
                        label: _capitalizeLabel(label),
                        onTap: () => _triggerQuick(a['text'] as String),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _triggerQuick(String text) async {
    if (_active == null) {
      await _createSession();
      // wait until active is set
      if (_active == null) return;
    }
    _msgCtrl.text = text;
    await _send();
  }

  Widget _buildMessageBubble(_Msg msg) {
    final isUser = msg.sender == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color.fromRGBO(27, 138, 62, 0.12),
                  child: Icon(Icons.eco, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.text,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              if (!isUser) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _speakMessage(msg),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(27, 138, 62, 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _speakingMessageId == msg.id
                          ? Icons.stop_rounded
                          : Icons.volume_up_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              if (isUser) const SizedBox(width: 8),
              if (isUser) ...[
                const SizedBox(width: 4),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color.fromRGBO(27, 138, 62, 0.12),
                  child: Icon(Icons.person, size: 14, color: AppColors.primary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding:
                EdgeInsets.only(left: isUser ? 0 : 46, right: isUser ? 46 : 0),
            child: Text(
              _formatTime(msg.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildTypingBubble() {
    final actions = [
      {
        'icon': Icons.agriculture,
        'label': 'Recommend a crop',
        'text': 'Recommend crop for my farm.'
      },
      {
        'icon': Icons.cloud,
        'label': 'Check the weather',
        'text': 'Show weather forecast.'
      },
      {
        'icon': Icons.healing,
        'label': 'Diagonise my plant',
        'text': 'Diagnose plant disease from symptoms.'
      },
      {
        'icon': Icons.local_florist,
        'label': 'Fertilizer advice',
        'text': 'Recommend fertilizer for my crops.'
      },
    ];

    final isWide = MediaQuery.of(context).size.width >= 700;
    final horizontalPadding = isWide ? 80.0 : 20.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 16,
        childAspectRatio: isWide ? 5.0 : 3.8,
        children: actions.map((a) {
          return AppButton(
            onPressed: () => _triggerQuick(a['text'] as String),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.darkPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(27, 138, 62, 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a['icon'] as IconData,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    a['label'] as String,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pickedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(_pickedImage!.path,
                            height: 80, fit: BoxFit.cover)
                        : Image.file(File(_pickedImage!.path),
                            height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _pickedImage = null),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade400, width: 1.6),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _active == null ? null : _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(27, 138, 62, 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        enabled: _active != null,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration.collapsed(
                          hintText: _active == null
                              ? 'Select or create a chat'
                              : 'Ask me about your farm...',
                        ),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: (_active == null || _voiceBusy || _sending)
                          ? null
                          : _toggleRecording,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _recording
                              ? Colors.red.shade50
                              : const Color.fromRGBO(27, 138, 62, 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: _voiceBusy
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                _recording
                                    ? Icons.stop_rounded
                                    : Icons.mic_none_rounded,
                                color:
                                    _recording ? Colors.red : AppColors.primary,
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _sending
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : InkWell(
                            onTap: _active == null ? null : _send,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                  ],
                ), // Row
              ), // Container
            ), // ConstrainedBox
          ), // Center
        ],
      ),
    );
  }
}

// ─── Animated Typing Dots ─────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value - i * 0.25) % 1.0;
            final opacity = (phase < 0.5 ? phase * 2.0 : (1.0 - phase) * 2.0)
                .clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
