import 'package:flutter/material.dart';

class PointsAnimationWidget extends StatefulWidget {
  final int points;
  final VoidCallback onCompleted;

  const PointsAnimationWidget({
    super.key,
    required this.points,
    required this.onCompleted,
  });

  @override
  State<PointsAnimationWidget> createState() => _PointsAnimationWidgetState();
}

class _PointsAnimationWidgetState extends State<PointsAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _positionAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Text(
            "+${widget.points}",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Theme
                  .of(context)
                  .colorScheme
                  .secondary, // 🎨 auto-theme
              shadows: [
                Shadow(
                  color: Theme
                      .of(context)
                      .primaryColor
                      .withOpacity(0.7),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}