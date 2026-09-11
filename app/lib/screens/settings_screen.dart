import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sign_provider.dart';

/// Settings screen — TTS language toggle, dark mode, backend URL
/// 🔵 P4 owns visual design; Person 2 provides settings infrastructure.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _ttsLanguage = 'both';
  String _backendUrl = 'http://10.0.2.2:8000';
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = _backendUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TTS Language Section
          _SectionHeader(title: 'Text-to-Speech Language'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'en',
                label: Text('English'),
                icon: Icon(Icons.language),
              ),
              ButtonSegment(
                value: 'hi',
                label: Text('Hindi'),
                icon: Icon(Icons.translate),
              ),
              ButtonSegment(
                value: 'both',
                label: Text('Both'),
                icon: Icon(Icons.record_voice_over),
              ),
            ],
            selected: {_ttsLanguage},
            onSelectionChanged: (Set<String> selected) {
              setState(() => _ttsLanguage = selected.first);
              ref.read(ttsServiceProvider).setLanguage(_ttsLanguage);
            },
          ),

          const SizedBox(height: 32),

          // Backend URL Section
          _SectionHeader(title: 'Backend Server'),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'API Base URL',
              hintText: 'http://10.0.2.2:8000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  final url = _urlController.text.trim();
                  if (url.isNotEmpty) {
                    setState(() => _backendUrl = url);
                    ref.read(apiServiceProvider).setBaseUrl(url);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backend URL updated')),
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 32),

          // App Info
          _SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🤟 SignBridge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Breaking barriers, one sign at a time.',
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  const Text('Version 1.0.0 — Hackathon Edition'),
                  const SizedBox(height: 4),
                  Text(
                    'Supported signs: 62',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
