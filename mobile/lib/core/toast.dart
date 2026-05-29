import 'dart:async';
import 'package:flutter/material.dart';

class Toast {
  static void show(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(builder: (ctx) {
      return _ToastWidget(message: message);
    });

    overlay.insert(entry);
    Timer(duration, () => entry.remove());
  }

  static void showTranslated(BuildContext context, String key,
      {Duration duration = const Duration(seconds: 3)}) {
    show(context, key, duration: duration);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  const _ToastWidget({required this.message});
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _ctrl,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
                  .animate(_ctrl),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(widget.message,
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
