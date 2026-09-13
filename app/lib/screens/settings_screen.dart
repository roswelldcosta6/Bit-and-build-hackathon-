import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_controller.dart';

import '../state/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final auth = ref.watch(authProvider);
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
          _SectionLabel('Account'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                if (auth.isSignedIn) ...[
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(
                      auth.user!.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(auth.user!.email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Role'),
                    trailing: Text(
                      _roleLabel(auth.user!.role),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: const Text('Preferred language'),
                    trailing: Text(
                      auth.user!.preferredLang.toUpperCase(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text(
                      'Sign out',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Guest'),
                    subtitle: const Text(
                      'Browsing without an account',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text(
                      'Sign out',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      // Guests exit to the landing page.
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) context.go('/landing');
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create an account to keep your translation history and preferences on the server.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: OutlinedButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Sign up or create an account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel('Accessibility'),
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
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel('Sign to Speak'),
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
          _SectionLabel('Backend connection'),
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit API base URL',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: settings.apiBaseUrl,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: 'http://host-ip:8000',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            notifier.update(settings.copyWith(apiBaseUrl: value));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final controller = TextEditingController(
                          text: settings.apiBaseUrl,
                        );
                        final result = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Update API base URL'),
                            content: SizedBox(
                              width: 380,
                              child: TextFormField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: 'http://host-ip:8000',
                                  border: OutlineInputBorder(),
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (v) =>
                                    v == null || v.isEmpty
                                        ? 'Enter a URL'
                                        : v.startsWith('http')
                                                ? null
                                                : 'Must start with http:// or https://',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, controller.text),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                        if (result != null) {
                          notifier.update(settings.copyWith(apiBaseUrl: result));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('API base URL updated to $result'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
  );
}

String _roleLabel(String role) => switch (role) {
  'deaf_user' => 'Deaf / Hard of hearing',
  'hearing_peer' => 'Hearing peer',
  'interpreter' => 'Interpreter',
  'healthcare_worker' => 'Healthcare worker',
  _ => role,
};
