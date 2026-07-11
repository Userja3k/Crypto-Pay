import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/haptic_service.dart';

class PaymentConfirmSlider extends StatefulWidget {
  final VoidCallback onConfirm;
  final bool isLoading;
  final String label;

  const PaymentConfirmSlider({
    super.key,
    required this.onConfirm,
    this.isLoading = false,
    this.label = 'Glisser pour payer',
  });

  @override
  State<PaymentConfirmSlider> createState() => _PaymentConfirmSliderState();
}

class _PaymentConfirmSliderState extends State<PaymentConfirmSlider>
    with TickerProviderStateMixin {
  double _slideProgress = 0.0;
  bool _isPressed = false;

  // Animation controllers
  late AnimationController _activeController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseScaleAnimation;
  late Animation<double> _pulseGlowAnimation;

  @override
  void initState() {
    super.initState();

    // Active state animations (touch and hold)
    _activeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _activeController, curve: Curves.easeOutBack),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _activeController, curve: Curves.easeOut),
    );

    // Pulse/breathing animations while holding
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseGlowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _activeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPressStart() {
    if (widget.isLoading) return;
    setState(() {
      _isPressed = true;
    });
    HapticService.selection();
    _activeController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _onPressEnd() {
    if (widget.isLoading) return;
    setState(() {
      _isPressed = false;
    });
    _pulseController.stop();
    _pulseController.reset();

    if (_slideProgress >= 0.85) {
      // Completed!
      setState(() {
        _slideProgress = 1.0;
      });
      HapticService.success();
      widget.onConfirm();
    } else {
      // Revert back
      HapticService.light();
      _activeController.reverse();
      _animateSlideBack();
    }
  }

  void _animateSlideBack() {
    final startVal = _slideProgress;
    final ctrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    final anim = Tween<double>(begin: startVal, end: 0.0).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
    );
    anim.addListener(() {
      setState(() {
        _slideProgress = anim.value;
      });
    });
    ctrl.forward().then((_) => ctrl.dispose());
  }

  void _onDragUpdate(DragUpdateDetails details, double maxSlide) {
    if (widget.isLoading || maxSlide <= 0) return;
    setState(() {
      _slideProgress = (_slideProgress + details.primaryDelta! / maxSlide).clamp(0.0, 1.0);
    });
    
    // Add subtle tick-like haptic feedback as we slide
    if ((_slideProgress * 10).round() % 2 == 0) {
      HapticService.selection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const knobSize = 56.0;
            final maxSlide = (constraints.maxWidth - knobSize - 8).clamp(0.0, double.infinity);
            final left = maxSlide * _slideProgress;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // 1. Slider Background / Container
                Container(
                  height: 72,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Active Progress Overlay Color (gradually fills green)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: constraints.maxWidth - left - knobSize,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                LiquidGlassTheme.accent.withValues(alpha: 0.15),
                                LiquidGlassTheme.accent.withValues(alpha: 0.35),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(36),
                              bottomLeft: const Radius.circular(36),
                              topRight: Radius.circular(_slideProgress > 0.9 ? 36 : 0),
                              bottomRight: Radius.circular(_slideProgress > 0.9 ? 36 : 0),
                            ),
                          ),
                        ),
                      ),
                      // Text Label
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _isPressed ? (1.0 - _slideProgress).clamp(0.1, 1.0) : 0.7,
                        child: Text(
                          widget.isLoading ? 'Envoi en cours...' : widget.label,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.7 + (_slideProgress * 0.3),
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Pulse Glow Effect (behind the knob, moves with it)
                AnimatedBuilder(
                  animation: Listenable.merge([_activeController, _pulseController]),
                  builder: (context, child) {
                    final activeVal = _glowAnimation.value;
                    final pulseVal = _pulseGlowAnimation.value;
                    final intensity = activeVal * (0.4 + (_slideProgress * 0.4)) * pulseVal;

                    if (intensity <= 0.01) return const SizedBox.shrink();

                    return Positioned(
                      left: left - 24,
                      top: -12,
                      child: Container(
                        width: knobSize + 48,
                        height: knobSize + 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              LiquidGlassTheme.accent.withValues(alpha: intensity * 0.6),
                              LiquidGlassTheme.accent.withValues(alpha: intensity * 0.2),
                              LiquidGlassTheme.accent.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 3. Sliding Knob Button
                Positioned(
                  left: left + 4,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => _onPressStart(),
                    onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxSlide),
                    onHorizontalDragEnd: (_) => _onPressEnd(),
                    onTapDown: (_) => _onPressStart(),
                    onTapUp: (_) => _onPressEnd(),
                    onTapCancel: () => _onPressEnd(),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_activeController, _pulseController]),
                      builder: (context, child) {
                        double scale = _scaleAnimation.value;
                        if (_isPressed) {
                          scale *= _pulseScaleAnimation.value;
                        }
                        if (widget.isLoading) {
                          scale = 0.85;
                        }

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: knobSize,
                            height: knobSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.white,
                                  Color(0xFFE2E8F0),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                                if (_isPressed)
                                  BoxShadow(
                                    color: LiquidGlassTheme.accent.withValues(
                                      alpha: 0.4 + (_slideProgress * 0.4),
                                    ),
                                    blurRadius: 25 * _glowAnimation.value,
                                    spreadRadius: 2 * _glowAnimation.value,
                                  ),
                              ],
                            ),
                            child: widget.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        LiquidGlassTheme.background,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.flash_on,
                                    size: 28,
                                    color: Colors.black,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
