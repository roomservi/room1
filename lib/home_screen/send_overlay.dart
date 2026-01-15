import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../library.dart';

// Full-screen attach overlay: blurs the chat and shows a centered large
// amount input (Apple Pay-like). Sending occurs by pressing Send. Only the
// input remains visually distinct above the blur.
class AttachFullOverlay extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final Future<void> Function(String amount, String note) onSend;

  const AttachFullOverlay({
    Key? key,
    required this.controller,
    required this.onCancel,
    required this.onSend,
  }) : super(key: key);

  @override
  State<AttachFullOverlay> createState() => _AttachFullOverlayState();
}

/// Show a SnackBar that respects system navigation bar and floats above it.
void showSafeSnackBar(
  BuildContext context,
  String text, {
  Duration duration = const Duration(seconds: 2),
}) {
  final bottomInset = MediaQuery.of(context).viewPadding.bottom;
  final double baseBottom = bottomInset + 24.0;
  final double bottomMargin = baseBottom < 48.0 ? 48.0 : baseBottom;
  final snack = SnackBar(
    content: Text(text),
    duration: duration,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
  );
  ScaffoldMessenger.of(context).showSnackBar(snack);
}

class _AttachFullOverlayState extends State<AttachFullOverlay> {
  final TextEditingController _noteController = TextEditingController();
  double _dragOffset = 0.0; // positive = pulled down, negative = pulled up
  bool _isDragging = false;
  static const double _sendThreshold = 120.0; // px to drag up to send

  void _trySend() {
    final amt = widget.controller.text;
    final note = _noteController.text;
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSend(amt, note);
    });
  }

  void _performSendIfThreshold() {
    if (-_dragOffset > _sendThreshold) {
      _trySend();
    } else {
      // reset
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // blurred background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            // centered amount input (unblurred, above the BackdropFilter)
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: media.size.width * 0.86,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // big amount display with drag-to-send behaviour
                          GestureDetector(
                            onVerticalDragStart: (_) {
                              setState(() {
                                _isDragging = true;
                                _dragOffset = 0.0;
                              });
                            },
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _dragOffset += details.delta.dy;
                              });
                            },
                            onVerticalDragEnd: (_) {
                              _performSendIfThreshold();
                            },
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                _dragOffset.clamp(-200.0, 200.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: CupertinoTextField(
                                  controller: widget.controller,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                  cursorColor: Colors.white,
                                  placeholder: '',
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  onSubmitted: (_) => _trySend(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // optional small note field
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: CupertinoTextField(
                              controller: _noteController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              placeholder: 'Aggiungi un messaggio (opzionale)',
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              onSubmitted: (_) => _trySend(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Drag hint: show upward arrow when dragging
                          AnimatedOpacity(
                            opacity: _isDragging ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 180),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white70,
                                    size: 28,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Scrolla verso l\'alto per inviare',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text(
                        'Annulla',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Overlay widget for incoming money: drops from top, blurs background and
// shows sender profile image and amount/note under it.
class IncomingMoneyOverlay extends StatefulWidget {
  final String fromUser;
  final String amountText;
  final VoidCallback onDismiss;

  const IncomingMoneyOverlay({
    Key? key,
    required this.fromUser,
    required this.amountText,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<IncomingMoneyOverlay> createState() => _IncomingMoneyOverlayState();
}

class _IncomingMoneyOverlayState extends State<IncomingMoneyOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _dropAnim;
  late final Animation<double> _profileOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _dropAnim = Tween<double>(
      begin: -120.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _profileOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    _ctrl.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final topInset =
        MediaQuery.of(context).viewPadding.top +
        8; // Adjusted to avoid system bars
    return Positioned(
      top: topInset,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, ch) {
            return Transform.translate(
              offset: Offset(0, _dropAnim.value),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: w * 0.9,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        FadeTransition(
                          opacity: _profileOpacity,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                getProfileImage(widget.fromUser),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                getDisplayName(widget.fromUser),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S${widget.amountText}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white24,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Small shared helper to show a quick overlay message when a ScaffoldMessenger
// may not be available (used from different widgets).
void showQuickOverlayMessage(
  BuildContext context,
  String text, {
  Duration duration = const Duration(seconds: 2),
  String? fromUser,
  String? amountText,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (ctx) {
      final w = MediaQuery.of(ctx).size.width;
      final topInset = MediaQuery.of(ctx).viewPadding.top;
      final bottomInset = MediaQuery.of(ctx).viewPadding.bottom;
      // Show a richer layout when fromUser/amountText are provided
      if (fromUser != null || amountText != null) {
        return Positioned(
          top: topInset + 28,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: Image.asset(
                            getProfileImage(fromUser ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fromUser != null
                                  ? getDisplayName(fromUser)
                                  : text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (amountText != null)
                              Text(
                                'S$amountText',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      final double bottomOffsetBase = bottomInset + 40.0;
      final double bottomOffset =
          bottomOffsetBase < 48.0 ? 48.0 : bottomOffsetBase;
      return Positioned(
        bottom: bottomOffset,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Future.delayed(duration, () {
    entry.remove();
  });
}

/// Convenience helper to show the incoming money overlay in the root overlay
void showIncomingNotification(
  BuildContext context,
  String fromUser,
  String amountText, {
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) => IncomingMoneyOverlay(
          fromUser: fromUser,
          amountText: amountText,
          onDismiss: () {
            if (entry.mounted) entry.remove();
          },
        ),
  );
  overlay.insert(entry);
  Future.delayed(duration, () {
    if (entry.mounted) entry.remove();
  });
}
