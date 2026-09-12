import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../state/avatar_provider.dart';

/// Mode B — Speak → Sign
/// Mic/text input → Whisper STT (backend) → Gloss mapping → Avatar animation
/// 🔵 P4 owns AvatarPlayer widget and mic UI polish; Person 2 provides the data pipeline.
class ModeBScreen extends ConsumerStatefulWidget {
  const ModeBScreen({super.key});

  @override
  ConsumerState<ModeBScreen> createState() => _ModeBScreenState();
}

class _ModeBScreenState extends ConsumerState<ModeBScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _textController = TextEditingController();
  bool _isRecording = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording and send to API
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        ref.read(avatarProvider.notifier).processAudio(path);
      }
    } else {
      // Start recording
      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, 'recording_${DateTime.now().millisecondsSinceEpoch}.wav');

      final hasPermission = await _audioRecorder.hasPermission();
      if (!mounted) return;
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
        return;
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );
      setState(() => _isRecording = true);
    }
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(avatarProvider.notifier).processText(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarState = ref.watch(avatarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤟 Speak → Sign'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(avatarProvider.notifier).reset(),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar display area (P4 will replace with AvatarPlayer widget)
              Expanded(
                flex: 5,
                child: _buildAvatarArea(avatarState),
              ),

              const SizedBox(height: 16),

              // Subtitle text
              if (avatarState.subtitle.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    avatarState.subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),

              // Text input field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type in English or Hindi...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _submitText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _submitText,
                    icon: const Icon(Icons.send),
                    tooltip: 'Translate text',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Mic button
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: avatarState.isProcessing ? null : _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop Recording' : 'Start Speaking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.teal,
                  ),
                ),
              ),

              // Gloss sequence display (P4 will integrate with avatar clips)
              if (avatarState.glosses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: avatarState.glosses.map((gloss) {
                    return Chip(
                      label: Text(gloss, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.teal.withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
              ],

              // Error display
              if (avatarState.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  avatarState.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarArea(AvatarState avatarState) {
    if (avatarState.isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text('Processing speech...'),
          ],
        ),
      );
    }

    // Placeholder — P4 will replace with AvatarPlayer widget
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.accessibility_new, size: 80, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Avatar Area\n(P4 will build AvatarPlayer here)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
