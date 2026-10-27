// lib/ui/mic_test_dialog.dart

import 'package:flutter/material.dart';
import 'package:voice_assistant_gui/services/settings_service.dart';

class MicTestDialog extends StatefulWidget {
  final SettingsService settings;
  final Function(double duration, double? gain) onTest;

  const MicTestDialog({
    super.key,
    required this.settings,
    required this.onTest,
  });

  @override
  State<MicTestDialog> createState() => _MicTestDialogState();
}

class _MicTestDialogState extends State<MicTestDialog> {
  final _durationController = TextEditingController(text: '3');
  final _gainController = TextEditingController();
  bool _isTesting = false;

  @override
  void dispose() {
    _durationController.dispose();
    _gainController.dispose();
    super.dispose();
  }

  void _runTest() {
    final duration = double.tryParse(_durationController.text) ?? 3.0;
    final gain = _gainController.text.isNotEmpty
        ? double.tryParse(_gainController.text)
        : null;

    setState(() => _isTesting = true);
    widget.onTest(duration, gain);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;

    return AlertDialog(
      title: const Text('Microphone Test'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record a short sample to check audio quality and transcription accuracy.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (seconds)',
                border: OutlineInputBorder(),
                suffixText: 's',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gainController,
              decoration: InputDecoration(
                labelText: 'Gain Override (optional)',
                border: const OutlineInputBorder(),
                hintText: 'Current: ${settings.inputGain.toStringAsFixed(2)}',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Settings:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('Input Gain: ${settings.inputGain.toStringAsFixed(2)}'),
                  Text(
                    'Auto Gain: ${settings.autoGain ? 'Enabled' : 'Disabled'}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isTesting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isTesting ? null : _runTest,
          icon: _isTesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mic),
          label: Text(_isTesting ? 'Testing...' : 'Start Test'),
        ),
      ],
    );
  }
}
