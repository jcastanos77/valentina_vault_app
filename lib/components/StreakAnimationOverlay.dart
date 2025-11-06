import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StreakAnimationOverlay extends StatefulWidget {
  const StreakAnimationOverlay({super.key});

  @override
  State<StreakAnimationOverlay> createState() => _StreakAnimationOverlayState();
}

class _StreakAnimationOverlayState extends State<StreakAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveUp;
  late Animation<double> _scaleDown;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _moveUp = Tween<double>(begin: 0, end: -200).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleDown = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeOut.value,
              child: Transform.translate(
                offset: Offset(0, _moveUp.value),
                child: Transform.scale(
                  scale: _scaleDown.value,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/loader/streak_fire.json',
                          width: 180,
                          height: 180,
                          repeat: false,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '+1 Día de Racha',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.orange, blurRadius: 20)
                            ],
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
