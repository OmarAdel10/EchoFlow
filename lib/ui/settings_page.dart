// lib/ui/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_assistant_gui/services/settings_service.dart';
import 'package:voice_assistant_gui/services/cli_service.dart';
import 'package:voice_assistant_gui/ui/mic_test_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Audio Settings
        _buildSectionHeader(context, 'Audio Settings'),
        _buildInputGainSlider(context),
        const SizedBox(height: 16),
        _buildAutoGainSwitch(context),
        const SizedBox(height: 16),
        _buildSampleRateInfo(context),

        const SizedBox(height: 24),

        // Language Settings
        _buildSectionHeader(context, 'Language'),
        _buildLanguageSelector(context),

        const SizedBox(height: 24),

        // CLI Settings
        _buildSectionHeader(context, 'CLI Configuration'),
        _buildCliPathField(context),
        const SizedBox(height: 16),
        _buildAutoStartSwitch(context),

        const SizedBox(height: 24),

        // Voice Enrollment
        _buildSectionHeader(context, 'Voice Enrollment'),
        _buildEnrollmentButton(context),

        const SizedBox(height: 24),

        // Microphone Test
        _buildSectionHeader(context, 'Microphone Test'),
        _buildMicTestButton(context),

        const SizedBox(height: 24),

        // About
        _buildSectionHeader(context, 'About'),
        _buildVersionInfo(context),
        const SizedBox(height: 16),
        _buildResetButton(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInputGainSlider(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Input Gain',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      settings.inputGain.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings.inputGain,
                  min: 0.01,
                  max: 2.0,
                  divisions: 199,
                  label: settings.inputGain.toStringAsFixed(2),
                  onChanged: (value) async {
                    final settingsService = context.read<SettingsService>();
                    final cliService = context.read<CliService>();
                    await settingsService.setInputGain(value);
                    cliService.sendSettingsCommand(inputGain: value);
                  },
                ),
                Text(
                  'Adjust microphone input volume. Lower values prevent clipping.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAutoGainSwitch(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Card(
          child: SwitchListTile(
            title: const Text('Auto Gain'),
            subtitle: const Text(
              'Automatically adjust input gain based on audio levels',
            ),
            value: settings.autoGain,
            onChanged: (value) async {
              final settingsService = context.read<SettingsService>();
              final cliService = context.read<CliService>();
              await settingsService.setAutoGain(value);
              cliService.sendSettingsCommand(autoGain: value);
            },
          ),
        );
      },
    );
  }

  Widget _buildSampleRateInfo(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Sample Rate'),
        subtitle: const Text('16 kHz (fixed for Whisper compatibility)'),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Card(
          child: RadioGroup<String>(
            groupValue: settings.language,
            onChanged: (value) async {
              await settings.setLanguage(value!);
            },
            child: Column(
              children: [
                const RadioListTile<String>(
                  title: Text('System Default'),
                  value: 'system',
                ),
                const RadioListTile<String>(
                  title: Text('English'),
                  value: 'en',
                ),
                const RadioListTile<String>(
                  title: Text('Arabic (العربية)'),
                  value: 'ar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCliPathField(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLI Path',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: settings.cliPath,
                  decoration: const InputDecoration(
                    hintText: 'voice-assistant',
                    border: OutlineInputBorder(),
                    helperText: 'Path to voice-assistant binary',
                  ),
                  onFieldSubmitted: (value) async {
                    await context.read<SettingsService>().setCliPath(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAutoStartSwitch(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Card(
          child: SwitchListTile(
            title: const Text('Auto Start'),
            subtitle: const Text(
              'Start voice assistant automatically on app launch',
            ),
            value: settings.autoStart,
            onChanged: (value) async {
              await context.read<SettingsService>().setAutoStart(value);
            },
          ),
        );
      },
    );
  }

  Widget _buildEnrollmentButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_add),
        title: const Text('Voice Enrollment'),
        subtitle: const Text('Record phrases to improve recognition accuracy'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.read<CliService>().sendEnrollCommand();
        },
      ),
    );
  }

  Widget _buildMicTestButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.mic),
        title: const Text('Test Microphone'),
        subtitle: const Text('Check audio levels and transcription quality'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => MicTestDialog(
              settings: context.read<SettingsService>(),
              onTest: (duration, gain) {
                context.read<CliService>().sendTestMicCommand(
                  duration: duration,
                  gain: gain,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info),
        title: const Text('Version'),
        subtitle: const Text('Voice Assistant GUI 1.0.0'),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restore, color: Colors.red),
        title: const Text(
          'Reset to Defaults',
          style: TextStyle(color: Colors.red),
        ),
        subtitle: const Text('Reset all settings to default values'),
        onTap: () async {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Settings?'),
              content: const Text(
                'This will reset all settings to their default values. This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await context.read<SettingsService>().resetToDefaults();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
