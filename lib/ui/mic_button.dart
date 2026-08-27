// lib/ui/mic_button.dart

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class MicButton extends StatefulWidget {
  final bool isConnected;
  final bool isUserSpeaking;
  final bool isAssistantSpeaking;
  final bool isProcessing;
  final VoidCallback onTap;
  final double size;

  const MicButton({
    super.key,
    required this.isConnected,
    required this.isUserSpeaking,
    required this.isAssistantSpeaking,
    required this.isProcessing,
    required this.onTap,
    this.size = 120,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isConnected || widget.isProcessing) return;
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isConnected || widget.isProcessing) return;
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = !widget.isConnected || widget.isProcessing;

    Color baseColor;
    Color iconColor;
    Color ringColor;
    List<BoxShadow> shadows;

    if (isDisabled) {
      baseColor = theme.colorScheme.surfaceContainerHighest;
      iconColor = theme.colorScheme.onSurfaceVariant;
      ringColor = theme.colorScheme.outlineVariant;
      shadows = [];
    } else if (widget.isUserSpeaking) {
      baseColor = Colors.teal;
      iconColor = Colors.white;
      ringColor = Colors.teal;
      shadows = [
        BoxShadow(
          color: Colors.teal.withValues(alpha: 0.4),
          blurRadius: 30,
          spreadRadius: 8,
        ),
      ];
    } else if (widget.isAssistantSpeaking) {
      baseColor = theme.colorScheme.secondary;
      iconColor = theme.colorScheme.onSecondary;
      ringColor = theme.colorScheme.secondary;
      shadows = [
        BoxShadow(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: 5,
        ),
      ];
    } else {
      baseColor = theme.colorScheme.primary;
      iconColor = theme.colorScheme.onPrimary;
      ringColor = theme.colorScheme.primary;
      shadows = [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          blurRadius: 20,
          spreadRadius: 3,
        ),
      ];
    }

    final hoverColor = isDisabled
        ? baseColor
        : Color.lerp(baseColor, Colors.white, 0.12)!;

    final effectiveShadows = _isHovered && !isDisabled
        ? [
            ...shadows,
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ]
        : shadows;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scaleByVector3(
              Vector3(
                _isPressed ? 0.92 : (_isHovered && !isDisabled ? 1.04 : 1.0),
                _isPressed ? 0.92 : (_isHovered && !isDisabled ? 1.04 : 1.0),
                1.0,
              ),
            ),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse rings (for user speaking)
                  if (widget.isUserSpeaking && !isDisabled) ...[
                    _PulsingRing(
                      animation: _pulseController,
                      delay: 0.0,
                      color: ringColor,
                      size: widget.size,
                    ),
                    _PulsingRing(
                      animation: _pulseController,
                      delay: 0.33,
                      color: ringColor,
                      size: widget.size,
                    ),
                    _PulsingRing(
                      animation: _pulseController,
                      delay: 0.66,
                      color: ringColor,
                      size: widget.size,
                    ),
                  ],
                  // Assistant speaking ripple
                  if (widget.isAssistantSpeaking && !isDisabled)
                    _AssistantRipple(
                      animation: _pulseController,
                      color: ringColor,
                      size: widget.size,
                    ),
                  // Main button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isHovered && !isDisabled ? hoverColor : baseColor,
                      boxShadow: effectiveShadows,
                      border: Border.all(
                        color: ringColor.withValues(
                          alpha: isDisabled ? 0.3 : 0.6,
                        ),
                        width: isDisabled ? 2 : 3,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          widget.isUserSpeaking
                              ? Icons.mic
                              : widget.isAssistantSpeaking
                              ? Icons.volume_up
                              : widget.isProcessing
                              ? Icons.hourglass_empty
                              : Icons.mic_none,
                          key: ValueKey(
                            widget.isUserSpeaking
                                ? 'speaking'
                                : widget.isAssistantSpeaking
                                ? 'assistant'
                                : widget.isProcessing
                                ? 'processing'
                                : 'idle',
                          ),
                          size: widget.size * 0.4,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                  // Subtle idle pulse
                  if (!widget.isUserSpeaking &&
                      !widget.isAssistantSpeaking &&
                      !widget.isProcessing &&
                      !isDisabled)
                    _IdlePulse(
                      animation: _pulseController,
                      color: ringColor,
                      size: widget.size,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PulsingRing extends StatelessWidget {
  final AnimationController animation;
  final double delay;
  final Color color;
  final double size;

  const _PulsingRing({
    required this.animation,
    required this.delay,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = (animation.value + delay) % 1.0;
        final scale = 1.0 + value * 0.6;
        final opacity = (1.0 - value) * 0.5;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AssistantRipple extends StatelessWidget {
  final AnimationController animation;
  final Color color;
  final double size;

  const _AssistantRipple({
    required this.animation,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        final scale = 1.0 + value * 0.4;
        final opacity = (1.0 - value) * 0.4;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IdlePulse extends StatelessWidget {
  final AnimationController animation;
  final Color color;
  final double size;

  const _IdlePulse({
    required this.animation,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        final scale = 1.0 + value * 0.03;
        final opacity = 0.15 + value * 0.1;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
              ),
            ),
          ),
        );
      },
    );
  }
}
