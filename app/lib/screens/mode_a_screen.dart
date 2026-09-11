import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sign_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/sign_result_card.dart';

/// Mode A — Sign → Speak
/// Camera preview → MediaPipe keypoints → TFLite inference → bilingual text + TTS
/// 🔵 P4 owns full visual polish; Person 2 provides the functional pipeline.
class ModeAScreen extends ConsumerStatefulWidget {
  const ModeAScreen({super.key});

  @override
  ConsumerState<ModeAScreen> createState() => _ModeAScreenState();
}

class _ModeAScreenState extends ConsumerState<ModeAScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start the sign recognition pipeline
    Future.microtask(() {
      ref.read(signRecognitionProvider.notifier).startProcessing();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause/resume camera when app goes to background
    final signState = ref.read(signRecognitionProvider);
    if (!signState.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      ref.read(signRecognitionProvider.notifier).stopProcessing();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(signRecognitionProvider.notifier).startProcessing();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(signRecognitionProvider.notifier).stopProcessing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signState = ref.watch(signRecognitionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: const Text('🤟 Sign → Speak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(signRecognitionProvider.notifier).clearSentence();
            },
            tooltip: 'Clear sentence',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview — top 60% of screen
          Expanded(
            flex: 6,
            child: signState.isInitialized
                ? CameraView(
                    cameraController:
                        ref.read(cameraServiceProvider).controller,
                  )
                : _buildLoadingState(signState),
          ),

          // Bottom panel — sign result + sentence builder + confidence
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current sign result card
                  SignResultCard(
                    result: signState.currentResult,
                    confidence: signState.confidence,
                  ),

                  const SizedBox(height: 12),

                  // Sentence builder — accumulated signs
                  Expanded(
                    child: _buildSentencePanel(signState),
                  ),

                  const SizedBox(height: 8),

                  // Confidence meter bar
                  _ConfidenceBar(confidence: signState.confidence),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(SignRecognitionState signState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (signState.errorMessage != null)
            Icon(Icons.error_outline, size: 48, color: Colors.red[300])
          else
            const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            signState.errorMessage ?? 'Initializing camera...',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSentencePanel(SignRecognitionState signState) {
    if (signState.sentence.isEmpty) {
      return Center(
        child: Text(
          'Start signing to build a sentence...',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // English sentence
          Text(
            signState.sentenceEn,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Hindi sentence
          Text(
            signState.sentenceHi,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          // Individual sign chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: signState.sentence.map((result) {
              return Chip(
                label: Text(
                  result.gloss,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: Colors.orange.withValues(alpha: 0.3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Confidence meter bar — visual feedback for signer
class _ConfidenceBar extends StatelessWidget {
  final double confidence;

  const _ConfidenceBar({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: confidence > 0.75 ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence > 0.85
                  ? Colors.green
                  : confidence > 0.75
                      ? Colors.orange
                      : Colors.red,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
