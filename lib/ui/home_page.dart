// lib/ui/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_assistant_gui/services/cli_service.dart';
import 'package:voice_assistant_gui/services/settings_service.dart';
import 'package:voice_assistant_gui/models/mic_test_result.dart' as mic;
import 'package:voice_assistant_gui/models/response.dart' as resp;
import 'package:voice_assistant_gui/ui/mic_button.dart';
import 'package:voice_assistant_gui/ui/mic_test_dialog.dart';
import 'package:voice_assistant_gui/ui/chat_view.dart';
import 'package:voice_assistant_gui/ui/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    final cliService = context.read<CliService>();
    final settings = context.read<SettingsService>();

    // Set CLI path from settings
    cliService.cliPath = settings.cliPath;

    // Start CLI service
    try {
      await cliService.start();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start voice assistant: $e')),
        );
      }
    }

    // Listen for responses
    cliService.responses.listen((response) {
      if (!mounted) return;
      _handleResponse(response);
    });

    cliService.micTestResults.listen((result) {
      if (mounted) {
        _showMicTestResult(result);
      }
    });

    cliService.statusUpdates.listen((status) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleResponse(resp.VoiceResponse response) {
    if (response.isTranscription) {
      // Add user message to chat
    } else if (response.isResponse) {
      // Add assistant response to chat
    } else if (response.isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Unknown error')),
      );
    }
  }

  void _showMicTestResult(mic.MicTestResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Test Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration: ${result.duration.toStringAsFixed(1)}s'),
              Text('RMS Level: ${result.rms.toStringAsFixed(4)}'),
              Text('Peak Level: ${result.peak.toStringAsFixed(4)}'),
              Text(
                'Clipping: ${result.clippedSamples}/${result.totalSamples} (${result.clippingPercentage.toStringAsFixed(1)}%)',
              ),
              Text('Language: ${result.detectedLanguage}'),
              Text('Transcription: "${result.transcription}"'),
              const SizedBox(height: 16),
              Text(
                result.assessment,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (result.suggestedGain != 0)
                Text(
                  'Suggested input_gain: ${result.suggestedGain.toStringAsFixed(3)}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: 'Voice'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none),
            onPressed: () => _showMicTestDialog(),
            tooltip: 'Test Microphone',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildVoiceTab(), _buildChatTab(), const SettingsPage()],
      ),
    );
  }

  Widget _buildVoiceTab() {
    final cliService = context.watch<CliService>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cliService.isRunning ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cliService.isRunning ? Icons.circle : Icons.circle_outlined,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  cliService.isRunning ? 'Connected' : 'Disconnected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Microphone button
          MicButton(
            isListening: cliService.isRunning,
            onTap: () {
              if (cliService.isRunning) {
                context.read<CliService>().sendVoiceCommand(mode: 'once');
              }
            },
          ),

          const SizedBox(height: 32),

          // Quick actions
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _QuickActionButton(
                icon: Icons.access_time,
                label: 'Time',
                onTap: () => context.read<CliService>().sendTextCommand(
                  'what time is it',
                ),
              ),
              _QuickActionButton(
                icon: Icons.calendar_today,
                label: 'Date',
                onTap: () => context.read<CliService>().sendTextCommand(
                  'what date is it',
                ),
              ),
              _QuickActionButton(
                icon: Icons.memory,
                label: 'System Info',
                onTap: () =>
                    context.read<CliService>().sendTextCommand('system info'),
              ),
              _QuickActionButton(
                icon: Icons.code,
                label: 'Open Code',
                onTap: () =>
                    context.read<CliService>().sendTextCommand('open code'),
              ),
              _QuickActionButton(
                icon: Icons.web,
                label: 'Search',
                onTap: () => _showSearchDialog(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Input gain display
          Consumer<SettingsService>(
            builder: (context, settings, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Input Gain: ${settings.inputGain.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (settings.autoGain) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.auto_mode,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return const ChatView();
  }

  void _showMicTestDialog() {
    final settings = context.read<SettingsService>();
    final cliService = context.read<CliService>();

    showDialog(
      context: context,
      builder: (context) => MicTestDialog(
        settings: settings,
        onTest: (duration, gain) {
          cliService.sendTestMicCommand(duration: duration, gain: gain);
        },
      ),
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Web Search'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter search query...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context);
              context.read<CliService>().sendTextCommand('search for $value');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                context.read<CliService>().sendTextCommand(
                  'search for ${controller.text}',
                );
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
