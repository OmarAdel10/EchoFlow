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
import 'package:voice_assistant_gui/services/chat_service.dart';

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
    final chatService = context.read<ChatService>();
    if (response.isTranscription &&
        response.text != null &&
        response.text!.isNotEmpty) {
      chatService.addTranscription(response.text!, response.lang ?? 'en');
    } else if (response.isResponse &&
        response.text != null &&
        response.text!.isNotEmpty) {
      chatService.replaceLoadingWithResponse(
        response.text!,
        cliLanguage: response.lang,
      );
    } else if (response.isError) {
      chatService.replaceLoadingWithError(response.message ?? 'Unknown error');
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
          Consumer<ChatService>(
            builder: (context, chatService, _) {
              return IconButton(
                icon: const Icon(Icons.mic_none),
                onPressed: chatService.isProcessing
                    ? null
                    : () => _showMicTestDialog(),
                tooltip: 'Test Microphone',
              );
            },
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
    final chatService = context.watch<ChatService>();
    final isProcessing = chatService.isProcessing;

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
            isConnected: cliService.isRunning,
            isUserSpeaking: cliService.isUserSpeaking,
            isAssistantSpeaking: cliService.isAssistantSpeaking,
            isProcessing: isProcessing,
            onTap: () {
              if (cliService.isRunning && !isProcessing) {
                context.read<CliService>().sendVoiceCommand(mode: 'once');
              }
            },
          ),

          const SizedBox(height: 48),

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
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Future<void> Function() onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = !widget.enabled;

    final baseColor = isDisabled
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.38)
        : theme.colorScheme.surfaceContainerHighest;
    final hoverColor = isDisabled
        ? baseColor
        : theme.colorScheme.primaryContainer;
    final iconColor = isDisabled
        ? theme.colorScheme.onSurfaceVariant
        : _isHovered
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.primary;
    final textColor = isDisabled
        ? theme.colorScheme.onSurfaceVariant
        : _isHovered
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) {
        if (!isDisabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (!isDisabled) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isHovered && !isDisabled ? hoverColor : baseColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: _elevationAnimation.value,
                      spreadRadius: 0,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 24, color: iconColor),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
