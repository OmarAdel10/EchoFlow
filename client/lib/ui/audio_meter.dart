// lib/ui/audio_meter.dart

import 'package:flutter/material.dart';

class AudioMeter extends StatefulWidget {
  final double level; // 0.0 to 1.0
  final double peak;
  final bool isRecording;
  final double width;
  final double height;

  const AudioMeter({
    super.key,
    required this.level,
    required this.peak,
    required this.isRecording,
    this.width = 200,
    this.height = 80,
  });

  @override
  State<AudioMeter> createState() => _AudioMeterState();
}

class _AudioMeterState extends State<AudioMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant AudioMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isRecording ? 'Recording...' : 'Idle',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: widget.isRecording
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'RMS: ${(widget.level * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Background track
                    Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight - 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Level bar
                    AnimatedAlign(
                      alignment: Alignment.bottomCenter,
                      duration: const Duration(milliseconds: 50),
                      curve: Curves.easeOut,
                      child: FractionallySizedBox(
                        heightFactor: widget.level.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                widget.level > 0.8
                                    ? theme.colorScheme.error
                                    : widget.level > 0.5
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                                widget.level > 0.8
                                    ? theme.colorScheme.error.withValues(
                                        alpha: 0.7,
                                      )
                                    : widget.level > 0.5
                                    ? theme.colorScheme.secondary.withValues(
                                        alpha: 0.7,
                                      )
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.7,
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Peak indicator
                    if (widget.peak > 0)
                      AnimatedAlign(
                        alignment: Alignment.bottomCenter,
                        duration: const Duration(milliseconds: 100),
                        child: FractionallySizedBox(
                          heightFactor: 0.04,
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom:
                                  (constraints.maxHeight - 20) *
                                  widget.peak.clamp(0.0, 1.0),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (widget.isRecording) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLevelIndicator(0.0, 0.25, 'Silence', Colors.grey),
                _buildLevelIndicator(0.25, 0.5, 'Low', Colors.orange),
                _buildLevelIndicator(0.5, 0.8, 'Good', Colors.green),
                _buildLevelIndicator(0.8, 1.0, 'High', Colors.red),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelIndicator(
    double min,
    double max,
    String label,
    Color color,
  ) {
    final isActive = widget.level >= min && widget.level < max;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
