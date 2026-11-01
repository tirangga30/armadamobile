import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/theme.dart';

class PttWalkieTalkieButton extends StatefulWidget {
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final bool isTransmitting;

  const PttWalkieTalkieButton({
    super.key,
    required this.onPressStart,
    required this.onPressEnd,
    this.isTransmitting = false,
  });

  @override
  State<PttWalkieTalkieButton> createState() => _PttWalkieTalkieButtonState();
}

class _PttWalkieTalkieButtonState extends State<PttWalkieTalkieButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePressDown() {
    if (_isPressed) return;
    setState(() => _isPressed = true);
    HapticFeedback.heavyImpact();
    _pulseController.repeat(reverse: true);
    widget.onPressStart();
  }

  void _handlePressUp() {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
    HapticFeedback.lightImpact();
    _pulseController.stop();
    _pulseController.reset();
    widget.onPressEnd();
  }

  @override
  Widget build(BuildContext context) {
    final active = _isPressed || widget.isTransmitting;
    final color = active ? AppTheme.statusDanger : AppTheme.primaryBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _handlePressDown(),
          onTapUp: (_) => _handlePressUp(),
          onTapCancel: () => _handlePressUp(),
          onLongPressStart: (_) => _handlePressDown(),
          onLongPressEnd: (_) => _handlePressUp(),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: active ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: active ? 0.5 : 0.25),
                        blurRadius: active ? 20 : 10,
                        spreadRadius: active ? 4 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      active ? Icons.mic_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          active ? 'SEDANG MENGIRIM SUARA...' : 'TEKAN UNTUK BICARA',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? AppTheme.statusDanger : AppTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
