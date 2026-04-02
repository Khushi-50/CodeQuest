import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/appcolors.dart';

class CyberButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const CyberButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton>
    with SingleTickerProviderStateMixin {
  // 1. Remove 'late' and make them nullable to prevent the crash
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  Animation<Color?>? _colorAnimation;

  @override
  void initState() {
    super.initState();

    // 2. Initialize everything immediately
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));

    _colorAnimation = ColorTween(
      begin: AppColors.background,
      end: AppColors.primary,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Helper methods to handle null safety
  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) _controller?.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      _controller?.reverse();
      HapticFeedback.lightImpact();
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Safety Check: If for some reason animations aren't ready, show a static version
    if (_controller == null ||
        _scaleAnimation == null ||
        _colorAnimation == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _controller?.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation!,
        child: AnimatedBuilder(
          animation: _controller!,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: _colorAnimation!.value,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isLoading
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  width: 2,
                ),
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          color: _controller!.value > 0.5
                              ? AppColors.textInverted
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1,
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
