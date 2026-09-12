import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Person 2: Camera preview widget
/// Displays live camera feed, mirrored for front camera (natural signing view).
class CameraView extends StatelessWidget {
  final CameraController? cameraController;

  const CameraView({super.key, required this.cameraController});

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: cameraController!.value.previewSize!.height,
            height: cameraController!.value.previewSize!.width,
            child: CameraPreview(cameraController!),
          ),
        ),
      ),
    );
  }
}
