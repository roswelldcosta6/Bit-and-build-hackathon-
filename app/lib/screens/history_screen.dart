import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: () => context.go('/home'),
      ),
      title: const Text('Conversation history'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          'Your translations',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Recent conversations stay here during your session.'),
        const SizedBox(height: 22),
        _HistoryTile(
          icon: Icons.record_voice_over_outlined,
          title: 'Where is the hospital?',
          output: 'HOSPITAL  •  WHERE',
          time: 'Mode B · Just now',
        ),
        _HistoryTile(
          icon: Icons.sign_language_outlined,
          title: 'Help',
          output: 'Help  /  मदद',
          time: 'Mode A · Demo',
        ),
      ],
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.icon,
    required this.title,
    required this.output,
    required this.time,
  });
  final IconData icon;
  final String title, output, time;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text('$output\n$time'),
      ),
      isThreeLine: true,
    ),
  );
}
