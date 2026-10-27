// lib/ui/enrollment_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_assistant_gui/models/enroll_state.dart';
import 'package:voice_assistant_gui/services/cli_service.dart';
import 'package:voice_assistant_gui/utils/arabic_utils.dart';

/// Interactive voice enrollment: one phrase at a time, tap-to-record,
/// forced retry on silence. Cancel is the only early exit.
class EnrollmentScreen extends StatefulWidget {
  final bool debugDisablePulse;
  final bool debugDisableAutoPop;

  const EnrollmentScreen({
    super.key,
    this.debugDisablePulse = false,
    this.debugDisableAutoPop = false,
  });

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

enum _Step { idle, waiting, busy, successFlash, done }

class _EnrollmentScreenState extends State<EnrollmentScreen>
    with TickerProviderStateMixin {
  StreamSubscription<EnrollState>? _sub;
  EnrollState? _state;
  _Step _step = _Step.idle;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    lowerBound: 0.92,
    upperBound: 1.08,
  );

  @override
  void initState() {
    super.initState();
    final cli = context.read<CliService>();
    _sub = cli.enrollStates.listen(_onState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cli.sendEnrollStart();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onState(EnrollState state) {
    if (!mounted) return;
    setState(() {
      _state = state;
      if (state.isStarted || state.isCaptured || state.isNoSpeech) {
        _step = _Step.waiting;
        _pulse.stop();
        _pulse.reset();
      } else if (state.isComplete) {
        _step = _Step.done;
      } else if (state.isCancelled) {
        Navigator.of(context).maybePop();
      }
    });

    if (!widget.debugDisableAutoPop) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _step == _Step.successFlash) {
          setState(() => _step = _Step.waiting);
        }
      });
    } else {
      setState(() => _step = _Step.waiting);
    }

    if (state.isComplete) {
      if (!widget.debugDisableAutoPop) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
    }
  }

  void _startRecording() {
    if (_step == _Step.busy || _step == _Step.done) return;
    context.read<CliService>().sendEnrollRecord();
    if (!widget.debugDisablePulse) {
      setState(() => _step = _Step.busy);
      _pulse.repeat(reverse: true);
    } else {
      setState(() => _step = _Step.busy);
    }
  }

  void _cancel() {
    context.read<CliService>().sendEnrollCancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Enrollment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
        ),
        body: SafeArea(child: _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_step == _Step.done && _state != null) return _buildCompleted(context);
    if (_state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildPhraseFlow(context);
  }

  // ------------------------------------------------------------------
  // Completed
  // ------------------------------------------------------------------
  Widget _buildCompleted(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Enrollment saved',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${_state!.captured} of ${_state!.total} phrases captured.\n'
            'Restart the assistant to apply.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Phrase flow
  // ------------------------------------------------------------------
  Widget _buildPhraseFlow(BuildContext context) {
    final state = _state!;
    final total = state.total == 0 ? 6 : state.total;

    return Column(
      children: [
        const Spacer(),
        _ProgressDots(
          total: total,
          current: state.index,
          captured: state.captured,
        ),
        const Spacer(),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _PhraseCard(
                key: ValueKey('${state.index}-${state.phase}'),
                phrase: state.phrase ?? '',
                transcription: state.transcription,
                showRetryHint: state.isNoSpeech,
              ),
            ),
          ),
        ),
        const Spacer(),
        _RecordButton(step: _step, pulse: _pulse, onTap: _startRecording),
        const SizedBox(height: 8),
        Text(_hintText(state), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 32),
      ],
    );
  }

  String _hintText(EnrollState state) {
    switch (_step) {
      case _Step.busy:
        return 'Listening… speak now';
      case _Step.successFlash:
        return 'Got it!';
      default:
        return state.isNoSpeech
            ? 'Nothing heard — check your mic and try again'
            : 'Tap the mic and read the phrase aloud';
    }
  }
}

// ------------------------------------------------------------------
// Helpers kept as plain widgets for testability
// ------------------------------------------------------------------
class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;
  final int captured;

  const _ProgressDots({
    required this.total,
    required this.current,
    required this.captured,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final done = i < captured;
        final active = i == current;
        return AnimatedContainer(
          key: ValueKey('dot-$i-$done-$active'),
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 26 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: done
                ? scheme.primary
                : active
                ? scheme.secondary
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  final String phrase;
  final String? transcription;
  final bool showRetryHint;

  const _PhraseCard({
    super.key,
    required this.phrase,
    this.transcription,
    this.showRetryHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rtl = ArabicUtils.isArabic(phrase);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Card.filled(
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Read this phrase', style: textTheme.labelMedium),
              const SizedBox(height: 16),
              Text(
                phrase,
                style: textTheme.headlineSmall?.copyWith(height: 1.4),
                textAlign: TextAlign.center,
              ),
              if (transcription != null && transcription!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  '"$transcription"',
                  style: textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final _Step step;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const _RecordButton({
    required this.step,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recording = step == _Step.busy;

    Widget icon;
    if (recording) {
      icon = const SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    } else if (step == _Step.successFlash) {
      icon = const Icon(Icons.check_rounded, size: 34);
    } else {
      icon = const Icon(Icons.mic_rounded, size: 34);
    }

    return ScaleTransition(
      scale: recording ? pulse : const AlwaysStoppedAnimation(1.0),
      child: ElevatedButton(
        onPressed: recording ? null : onTap,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(24),
          backgroundColor: recording
              ? scheme.errorContainer
              : scheme.secondaryContainer,
        ),
        child: icon,
      ),
    );
  }
}
