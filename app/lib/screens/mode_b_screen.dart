import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:permission_handler/permission_handler.dart";
import "package:speech_to_text/speech_to_text.dart" as stt;
import "package:video_player/video_player.dart";

import "../services/isl_translator.dart";

class ModeBScreen extends ConsumerStatefulWidget {
  const ModeBScreen({super.key});
  @override
  ConsumerState<ModeBScreen> createState() => _ModeBScreenState();
}

class _ModeBScreenState extends ConsumerState<ModeBScreen> {
  final _text = TextEditingController(text: "Thank you");
  final _speech = stt.SpeechToText();

  bool _loading = true;
  bool _speechInitialized = false;
  bool _userWantsMic = false;
  bool _listening = false;
  String _speechLocale = "en-IN"; // "en-IN" for Indian English / Hinglish, "hi-IN" for Hindi
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
    final newCtrl = VideoPlayerController.asset(videoPath);

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

  Future<void> _toggleSpeech() async {
    // 1. If currently listening, stop
    if (_listening || _userWantsMic) {
      _userWantsMic = false;
      setState(() => _listening = false);
      try {
        await _speech.stop();
      } catch (_) {}
      return;
    }

    _userWantsMic = true;
    setState(() {
      _listening = true;
      _error = null;
    });

    // 2. Request microphone permission explicitly on Mobile
    if (!kIsWeb) {
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final req = await Permission.microphone.request();
        if (!req.isGranted) {
          _userWantsMic = false;
          if (mounted) {
            setState(() {
              _listening = false;
              _error = "Microphone permission required for voice input.";
            });
          }
          return;
        }
      }
    }

    // 3. Initialize speech-to-text if not done yet
    if (!_speechInitialized) {
      try {
        _speechInitialized = await _speech.initialize(
          onStatus: _onSpeechStatus,
          onError: _onSpeechError,
        );
      } catch (e) {
        _speechInitialized = false;
      }
    }

    if (!_speechInitialized) {
      _userWantsMic = false;
      if (mounted) {
        setState(() {
          _listening = false;
          _error = "Microphone access not available. Please allow mic permissions in browser settings.";
        });
      }
      return;
    }

    // 4. Start continuous listening loop
    _startListeningLoop();
  }

  Future<void> _startListeningLoop() async {
    if (!_userWantsMic || !mounted) return;

    setState(() {
      _listening = true;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted && result.recognizedWords.isNotEmpty) {
            setState(() {
              _text.text = result.recognizedWords;
              _text.selection = TextSelection.fromPosition(
                TextPosition(offset: _text.text.length),
              );
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          localeId: _speechLocale,
        ),
      );
    } catch (_) {
      if (_userWantsMic && mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_userWantsMic && mounted) _startListeningLoop();
        });
      }
    }
  }

  void _onSpeechStatus(String status) {
    // Keep mic ON until the user presses the stop button!
    // If the browser ends session due to pause or silence, immediately restart:
    if (_userWantsMic && (status == "notListening" || status == "done")) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_userWantsMic && mounted) {
          _startListeningLoop();
        }
      });
    }
  }

  void _onSpeechError(dynamic errorNotification) {
    final msg = errorNotification?.errorMsg?.toString().toLowerCase() ?? "";

    // User requested to remove network error - suppress network, no-speech, and aborted
    if (msg.contains("network") || msg.contains("no-speech") || msg.contains("aborted")) {
      if (_userWantsMic && mounted) {
        if (_speechLocale == "en-IN" && msg.contains("network")) {
          // If en-IN had cloud lookup glitch on Edge, seamlessly try en-US
          _speechLocale = "en-US";
        }
        Future.delayed(const Duration(milliseconds: 400), () {
          if (_userWantsMic && mounted) _startListeningLoop();
        });
      }
      return;
    }

    if (msg.contains("not-allowed") || msg.contains("permission")) {
      _userWantsMic = false;
      if (mounted) {
        setState(() {
          _listening = false;
          _error = "Microphone permission denied. Please allow microphone access in your browser.";
        });
      }
      return;
    }

    if (_userWantsMic && mounted) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_userWantsMic && mounted) _startListeningLoop();
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _speech.stop();
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

                  // ── Text input Card with Speech-to-Text Microphone ─────
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header + Language selector for Speech
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Enter text or speak into mic",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // Language Toggle (English/Hinglish vs Hindi)
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _LangPill(
                                      label: "EN (Hinglish)",
                                      selected: _speechLocale == "en_IN",
                                      onTap: () {
                                        if (_listening) _speech.stop();
                                        setState(() {
                                          _speechLocale = "en_IN";
                                          _listening = false;
                                        });
                                      },
                                    ),
                                    _LangPill(
                                      label: "हिन्दी (HI)",
                                      selected: _speechLocale == "hi_IN",
                                      onTap: () {
                                        if (_listening) _speech.stop();
                                        setState(() {
                                          _speechLocale = "hi_IN";
                                          _listening = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Live Listening Status Banner
                          if (_listening)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _speechLocale == "hi_IN"
                                          ? "सुन रहा हूँ (हिन्दी)... बोलें"
                                          : "Listening (English / Hinglish)... Speak now",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _toggleSpeech,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text("Done", style: TextStyle(color: Colors.red, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),

                          // Text field with direct mic inside suffixIcon
                          TextField(
                            controller: _text,
                            decoration: InputDecoration(
                              hintText: _speechLocale == "hi_IN"
                                  ? "जैसे: धन्यवाद, घर कहाँ है, मत जाओ"
                                  : "e.g. Thank you, Where is home, Come here",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: _listening
                                        ? "Stop listening"
                                        : "Tap to speak (${_speechLocale == 'hi_IN' ? 'Hindi' : 'English / Hinglish'})",
                                    icon: Icon(
                                      _listening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                                      color: _listening ? Colors.red : const Color(0xFF10B981),
                                      size: 26,
                                    ),
                                    onPressed: _toggleSpeech,
                                  ),
                                  IconButton(
                                    tooltip: "Translate to Sign",
                                    icon: const Icon(Icons.send_rounded),
                                    onPressed: _submitting ? null : () => _translateText(),
                                  ),
                                ],
                              ),
                            ),
                            onSubmitted: (_) => _translateText(),
                            textInputAction: TextInputAction.send,
                          ),
                          const SizedBox(height: 10),

                          // Action row: Translate Button + Full Speech Mic Button
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: FilledButton.icon(
                                  onPressed: _submitting ? null : () => _translateText(),
                                  icon: _submitting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.translate_rounded, size: 18),
                                  label: Text(_submitting ? "Translating…" : "Translate to Sign"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed: _toggleSpeech,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _listening
                                        ? Colors.red
                                        : const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  icon: Icon(
                                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _listening ? "Stop Mic" : "Speak Mic",
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
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

                  if (_error != null &&
                      !_error!.toLowerCase().contains("network") &&
                      !_error!.toLowerCase().contains("no-speech") &&
                      !_error!.toLowerCase().contains("speech recognition")) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _LangPill extends StatelessWidget {
  const _LangPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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
