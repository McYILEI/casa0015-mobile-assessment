import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CountDisplay extends StatefulWidget {
  final int count;
  final double fontSize;

  const CountDisplay({super.key, required this.count, this.fontSize = 80});

  @override
  State<CountDisplay> createState() => _CountDisplayState();
}

class _CountDisplayState extends State<CountDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.count;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(CountDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != _prev) {
      _prev = widget.count;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Text(
        '${widget.count}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
          shadows: [
            Shadow(
              color: AppColors.accent.withAlpha(120),
              blurRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
