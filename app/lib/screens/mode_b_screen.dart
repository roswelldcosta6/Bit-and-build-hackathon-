import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/avatar_player.dart';

class ModeBScreen extends ConsumerStatefulWidget {
  const ModeBScreen({super.key});
  @override
  ConsumerState<ModeBScreen> createState() => _ModeBScreenState();
}

class _ModeBScreenState extends ConsumerState<ModeBScreen> {
  final _text = TextEditingController(text: 'Where is the hospital?');
  final _recorder = AudioRecorder();
  TranslationResult? _result;
  bool _recording = false;
  bool _submitting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _translateText());
  }

  Future<void> _translateText() async {
    if (_text.text.trim().isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(apiServiceProvider)
          .translateText(_text.text.trim());
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _result = _demoResult(_text.text.trim());
          _error = 'Backend unavailable. Showing local avatar preview.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) {
        setState(() => _submitting = true);
        try {
          final result = await ref
              .read(apiServiceProvider)
              .translateAudio(File(path));
          if (mounted) {
            setState(() => _result = result);
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _result = _demoResult('I need help');
              _error = 'Could not reach speech service. Showing local preview.';
            });
          }
        } finally {
          if (mounted) {
            setState(() => _submitting = false);
          }
        }
      }
      return;
    }
    if (!await Permission.microphone.request().isGranted) {
      if (mounted) {
        setState(
          () => _error = 'Microphone permission is needed to record speech.',
        );
      }
      return;
    }
    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}signbridge_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: path,
    );
    if (mounted) {
      setState(() => _recording = true);
    }
  }

  TranslationResult _demoResult(String input) => TranslationResult(
    originalText: input,
    subtitle: 'Hospital Where',
    language: 'en',
    glosses: const ['HOSPITAL', 'WHERE'],
    actions: const [
      AvatarAction(
        gloss: 'HOSPITAL',
        durationMs: 1500,
        poseEndpoint: '/avatar/poses/HOSPITAL',
      ),
      AvatarAction(
        gloss: 'WHERE',
        durationMs: 1400,
        poseEndpoint: '/avatar/poses/WHERE',
      ),
    ],
  );
  @override
  void dispose() {
    _text.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Speak to Sign')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            SizedBox(
              height: 310,
              child: AvatarPlayer(
                actions: result?.actions ?? const [],
                api: ref.read(apiServiceProvider),
              ),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Text(
              result?.subtitle ?? 'Type or speak a message to start.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (result != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: result.glosses
                      .map((g) => Chip(label: Text(g.replaceAll('_', ' '))))
                      .toList(),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _text,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _translateText(),
              decoration: InputDecoration(
                hintText: 'Type in English or Hindi',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  onPressed: _submitting ? null : _translateText,
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _recording
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              onPressed: _submitting ? null : _toggleRecord,
              icon: Icon(
                _recording ? Icons.stop_rounded : Icons.mic_none_rounded,
              ),
              label: Text(
                _recording
                    ? 'Stop and translate'
                    : 'Hold a spoken conversation',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _recording
                  ? 'Listening… tap to finish your sentence.'
                  : 'Your speech is auto-detected as Hindi or English.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
