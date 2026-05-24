import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class ChatPage extends StatefulWidget {
  final String accessToken;
  const ChatPage({super.key, required this.accessToken});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  String? _sessionId;
  final List<_ChatMsg> _messages = [];
  bool _isLoading = false;
  bool _sessionCreating = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      };

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    setState(() => _sessionCreating = true);
    try {
      for (final base in ['http://localhost:8000', 'http://10.0.2.2:8000']) {
        try {
          final resp = await http.post(
            Uri.parse('$base/api/chat/sessions'),
            headers: _headers,
            body: jsonEncode({'title': 'New chat'}),
          );
          if (resp.statusCode == 201) {
            final data = jsonDecode(resp.body);
            setState(() => _sessionId = data['session_id'] as String);
            return;
          }
        } catch (_) {}
      }
    } finally {
      setState(() => _sessionCreating = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sessionId == null || _isLoading) return;

    setState(() {
      _messages.add(_ChatMsg(sender: 'user', content: text));
      _msgController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      for (final base in ['http://localhost:8000', 'http://10.0.2.2:8000']) {
        try {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('$base/api/chat/sessions/$_sessionId/messages'),
          )
            ..headers['Authorization'] = 'Bearer ${widget.accessToken}'
            ..fields['message'] = text;

          final streamed = await request.send();
          final resp = await http.Response.fromStream(streamed);

          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            final data = jsonDecode(resp.body);
            final reply = data['assistant_message']['content'] as String;
            setState(() => _messages.add(_ChatMsg(sender: 'assistant', content: reply)));
            _scrollToBottom();
            return;
          }
        } catch (_) {}
      }
      setState(() => _messages.add(
            _ChatMsg(sender: 'assistant', content: 'Sorry, something went wrong. Please try again.'),
          ));
      _scrollToBottom();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Farmly AI',
              style: TextStyle(
                color: AppColors.darkPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: _sessionCreating
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (_isLoading && i == _messages.length) {
                              return _TypingIndicator();
                            }
                            return _MessageBubble(msg: _messages[i]);
                          },
                        ),
                ),
                _inputBar(),
              ],
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hi! I\'m your Farmly AI assistant.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ask me anything about your crops, soil, or weather.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask about your crops...',
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final String sender;
  final String content;
  _ChatMsg({required this.sender, required this.content});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.text,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const SizedBox(
          width: 40,
          child: LinearProgressIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.backgroundLight,
          ),
        ),
      ),
    );
  }
}
