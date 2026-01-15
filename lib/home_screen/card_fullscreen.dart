import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../library.dart';

class CardFullscreenView extends StatefulWidget {
  final String cardAsset;
  final bool isDark;
  final Function(double) onVerticalDragUpdate;
  final VoidCallback onDismiss;

  const CardFullscreenView({
    Key? key,
    required this.cardAsset,
    required this.isDark,
    required this.onVerticalDragUpdate,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<CardFullscreenView> createState() => _CardFullscreenViewState();
}

class _CardFullscreenViewState extends State<CardFullscreenView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _scaleAnimation;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _hasDataBeenSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDismissAnimation() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _startDismissAnimation();
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Sfondo sfocato
                GestureDetector(
                  onTapDown: (_) => _startDismissAnimation(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blurAnimation.value,
                      sigmaY: _blurAnimation.value,
                    ),
                    child: Container(
                      color:
                          widget.isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
                // Card centrale
                Center(
                  child: GestureDetector(
                    onVerticalDragStart: (_) {
                      setState(() => _isDragging = true);
                    },
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _dragOffset += details.primaryDelta ?? 0;
                        if (_dragOffset < -100 && !_hasDataBeenSaved) {
                          _hasDataBeenSaved = true;
                          widget.onVerticalDragUpdate(
                            details.primaryDelta ?? 0,
                          );
                          _startDismissAnimation();
                        }
                      });
                    },
                    onVerticalDragEnd: (_) {
                      if (_dragOffset > -100) {
                        setState(() {
                          _dragOffset = 0;
                          _isDragging = false;
                        });
                      }
                    },
                    child: Transform.translate(
                      offset: Offset(0, _dragOffset),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Hero(
                          tag: 'card_hero',
                          child: Image.asset(
                            widget.cardAsset,
                            height: 240,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Indicatore di scroll
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            widget.isDark
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
