import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../state/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Accessibility',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark mode'),
                  subtitle: const Text('Use a darker, low-light interface'),
                  value: settings.darkMode,
                  onChanged: (value) =>
                      notifier.update(settings.copyWith(darkMode: value)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Text size'),
                  subtitle: Slider(
                    value: settings.fontScale,
                    min: .9,
                    max: 1.3,
                    divisions: 4,
                    label: '${(settings.fontScale * 100).round()}%',
                    onChanged: (value) =>
                        notifier.update(settings.copyWith(fontScale: value)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Sign to Speak',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<SpeechLanguage>(
                segments: const [
                  ButtonSegment(
                    value: SpeechLanguage.english,
                    label: Text('English'),
                  ),
                  ButtonSegment(
                    value: SpeechLanguage.hindi,
                    label: Text('Hindi'),
                  ),
                  ButtonSegment(
                    value: SpeechLanguage.both,
                    label: Text('Both'),
                  ),
                ],
                selected: {settings.speechLanguage},
                onSelectionChanged: (value) => notifier.update(
                  settings.copyWith(speechLanguage: value.first),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Backend connection',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: const Text('API base URL'),
              subtitle: Text(settings.apiBaseUrl),
              trailing: const Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Android emulator uses 10.0.2.2 to reach the local FastAPI server.',
          ),
        ],
      ),
    );
  }
}
