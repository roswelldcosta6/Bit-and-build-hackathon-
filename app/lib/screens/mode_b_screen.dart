import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:permission_handler/permission_handler.dart";
import "package:record/record.dart";
import "package:video_player/video_player.dart";

import "../services/isl_translator.dart";

class ModeBScreen extends ConsumerStatefulWidget {
  const ModeBScreen({super.key});
  @override
  ConsumerState<ModeBScreen> createState() => _ModeBScreenState();
}

class _ModeBScreenState extends ConsumerState<ModeBScreen> {
  final _text = TextEditingController(text: "Thank you");
  final _recorder = AudioRecorder();

  bool _loading = true;
  bool _recording = false;
  bool _submitting = false;
  String? _error;

  TranslateResult? _result;
  int _currentIdx = 0;
  bool _playing = false;
  bool _done = false;

  VideoPlayerController? _videoCtrl;

  @override
  void initState() {
    super.initState();
    _initTranslator();
  }

  Future<void> _initTranslator() async {
    try {
      await IslTranslator.instance.load();
    } catch (e) {
      if (mounted) setState(() => _error = "Failed to load ISL dictionary: $e");
    }
    if (mounted) {
      setState(() => _loading = false);
      _translateText();
    }
  }

  void _translateText([String? customText]) {
    final query = (customText ?? _text.text).trim();
    if (query.isEmpty) return;
    if (customText != null) _text.text = customText;

    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
      _currentIdx = 0;
      _done = false;
    });

    try {
      final result = IslTranslator.instance.translate(query);
      setState(() {
        _result = result;
        _submitting = false;
      });
      if (result.glossSequence.isNotEmpty) {
        _playFrom(0);
      } else {
        setState(() => _done = true);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  Future<void> _playFrom(int index) async {
    final glosses = _result?.glossSequence;
    if (glosses == null || index >= glosses.length) {
      if (mounted) setState(() { _playing = false; _done = true; });
      return;
    }

    setState(() { _currentIdx = index; _playing = true; _done = false; });

    final videoPath = glosses[index].video;
    final newCtrl = kIsWeb
        ? VideoPlayerController.asset(videoPath)
        : VideoPlayerController.asset(videoPath);

    try {
      await newCtrl.initialize();
    } catch (e) {
      newCtrl.dispose();
      if (mounted) {
        _playFrom(index + 1); // skip missing video
      }
      return;
    }

    _videoCtrl?.dispose();
    _videoCtrl = newCtrl;

    if (!mounted) { newCtrl.dispose(); return; }
    setState(() {});

    newCtrl.addListener(() {
      if (!mounted) return;
      if (newCtrl.value.isInitialized &&
          !newCtrl.value.isPlaying &&
          newCtrl.value.position >= newCtrl.value.duration) {
        _playFrom(index + 1);
      }
    });

    await newCtrl.play();
  }

  void _replay() {
    if (_result != null && _result!.glossSequence.isNotEmpty) {
      setState(() { _done = false; });
      _playFrom(0);
    }
  }

  Future<void> _toggleRecord() async {
    if (kIsWeb) {
      _translateText("Where is home");
      return;
    }
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) {
        _translateText("Thank you"); // STT fallback for demo
      }
      return;
    }
    if (!await Permission.microphone.request().isGranted) {
      if (mounted) setState(() => _error = "Microphone permission required.");
      return;
    }
    final path =
        "${Directory.systemTemp.path}${Platform.pathSeparator}signbridge_${DateTime.now().millisecondsSinceEpoch}.wav";
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
    if (mounted) setState(() => _recording = true);
  }

  @override
  void dispose() {
    _text.dispose();
    _recorder.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glosses = result?.glossSequence ?? [];
    final currentGloss = glosses.isNotEmpty && _currentIdx < glosses.length
        ? glosses[_currentIdx].gloss
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: "Back",
          onPressed: () => context.canPop() ? context.pop() : context.go("/home"),
        ),
        title: const Text("Text to Sign"),
        actions: [
          IconButton(
            tooltip: "Reset Hello",
            icon: const Icon(Icons.waving_hand_outlined),
            onPressed: () => _translateText("Hello"),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  // ── Video player area ──────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildVideoArea(context, isDark, currentGloss),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Gloss label + status ────────────────────────────────
                  if (currentGloss != null)
                    Center(
                      child: Text(
                        currentGloss.replaceAll("_", " "),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),

                  // ── Gloss chips ─────────────────────────────────────────
                  if (glosses.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        for (int i = 0; i < glosses.length; i++)
                          _GlossChip(
                            label: glosses[i].gloss.replaceAll("_", " "),
                            active: i == _currentIdx && _playing,
                            done: i < _currentIdx || (_done && i == glosses.length - 1),
                          ),
                      ],
                    ),
                  ],

                  // ── Unknown words warning ───────────────────────────────
                  if (result != null && result.unknownWords.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "No sign available for: ${result.unknownWords.join(", ")}",
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Text input ─────────────────────────────────────────
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Enter text or use microphone",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              )),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _text,
                            decoration: InputDecoration(
                              hintText: "e.g. Thank you, Where is home, मत जाओ",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send_rounded),
                                onPressed: _submitting ? null : () => _translateText(),
                              ),
                            ),
                            onSubmitted: (_) => _translateText(),
                            textInputAction: TextInputAction.send,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _submitting ? null : () => _translateText(),
                                  icon: _submitting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.translate_rounded, size: 18),
                                  label: Text(_submitting ? "Translating…" : "Translate"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.tonal(
                                onPressed: _toggleRecord,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _recording ? Colors.red.withValues(alpha: 0.15) : null,
                                ),
                                child: Icon(
                                  _recording ? Icons.stop_rounded : Icons.mic_rounded,
                                  color: _recording ? Colors.red : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Demo phrases ────────────────────────────────────────
                  const SizedBox(height: 14),
                  Text("Demo phrases",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final phrase in const [
                        "Thank you",
                        "Where is home",
                        "Come here",
                        "Do not go",
                        "Who are you",
                        "My name",
                        "आपका नाम क्या है",
                        "मत जाओ",
                        "यहाँ आओ",
                      ])
                        ActionChip(
                          label: Text(phrase, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _translateText(phrase),
                        ),
                    ],
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildVideoArea(BuildContext context, bool isDark, String? currentGloss) {
    final ctrl = _videoCtrl;
    if (ctrl != null && ctrl.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: ctrl.value.size.width,
              height: ctrl.value.size.height,
              child: VideoPlayer(ctrl),
            ),
          ),
          if (_done)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 52),
              ),
            ),
          if (_done)
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: "replay",
                onPressed: _replay,
                child: const Icon(Icons.replay_rounded),
              ),
            ),
        ],
      );
    }

    // Placeholder while loading/waiting
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF132B25), const Color(0xFF0D3B2E)]
              : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _done ? Icons.check_circle_rounded : Icons.sign_language_rounded,
            color: const Color(0xFF10B981),
            size: 52,
          ),
          const SizedBox(height: 10),
          Text(
            _submitting
                ? "Translating…"
                : _done
                    ? "Sequence complete"
                    : "Video player ready",
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF065F46),
              fontSize: 14,
            ),
          ),
          if (_done) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _replay,
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: const Text("Replay"),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlossChip extends StatelessWidget {
  const _GlossChip({required this.label, required this.active, required this.done});
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF10B981)
        : done
            ? const Color(0xFF10B981).withValues(alpha: 0.4)
            : null;
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: active
            ? const Color(0xFF10B981)
            : done
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }
}
