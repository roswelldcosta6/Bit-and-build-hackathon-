"""
MediaPipe Holistic Feature Extractor for ISL Videos
Extracts 195 normalized keypoints per frame (Pose + Left Hand + Right Hand).
"""

import cv2
import numpy as np
from typing import Optional, Tuple, List

try:
    import mediapipe as mp
    MP_AVAILABLE = True
except ImportError:
    MP_AVAILABLE = False


class ISLFeatureExtractor:
    def __init__(self, target_frames: int = 30):
        self.target_frames = target_frames
        if MP_AVAILABLE:
            self.mp_holistic = mp.solutions.holistic.Holistic(
                static_image_mode=False,
                model_complexity=1,
                min_detection_confidence=0.5,
                min_tracking_confidence=0.5,
            )
        else:
            self.mp_holistic = None

    def extract_landmarks_from_frame(self, frame_bgr: np.ndarray) -> np.ndarray:
        """
        Extracts 195-dimensional feature vector from a single video frame.
        Pose (33 landmarks x 3 = 99 - lower legs = 69) + Left Hand (21 x 3 = 63) + Right Hand (21 x 3 = 63) = 195.
        """
        if not MP_AVAILABLE or self.mp_holistic is None:
            # Synthetic / fallback zero vector
            return np.zeros(195, dtype=np.float32)

        frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
        results = self.mp_holistic.process(frame_rgb)

        # 1. Pose landmarks (top 23 keypoints: head, shoulders, elbows, wrists = 23 * 3 = 69)
        pose_feat = []
        if results.pose_landmarks:
            for lm in results.pose_landmarks.landmark[:23]:
                pose_feat.extend([lm.x, lm.y, lm.z])
        else:
            pose_feat = [0.0] * 69

        # 2. Left hand landmarks (21 * 3 = 63)
        lh_feat = []
        if results.left_hand_landmarks:
            for lm in results.left_hand_landmarks.landmark:
                lh_feat.extend([lm.x, lm.y, lm.z])
        else:
            lh_feat = [0.0] * 63

        # 3. Right hand landmarks (21 * 3 = 63)
        rh_feat = []
        if results.right_hand_landmarks:
            for lm in results.right_hand_landmarks.landmark:
                rh_feat.extend([lm.x, lm.y, lm.z])
        else:
            rh_feat = [0.0] * 63

        combined = np.array(pose_feat + lh_feat + rh_feat, dtype=np.float32)
        if len(combined) != 195:
            combined = np.pad(combined, (0, max(0, 195 - len(combined))))[:195]
        return combined

    def extract_video_features(self, video_path: str) -> Tuple[np.ndarray, np.ndarray]:
        """
        Extracts both RGB frames array and 195-dim skeletal keypoints sequence
        sampled uniformly to target_frames length (default 30).
        """
        cap = cv2.VideoCapture(video_path)
        raw_frames = []

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            raw_frames.append(frame)
        cap.release()

        total = len(raw_frames)
        if total == 0:
            raise ValueError(f"No frames could be read from {video_path}")

        # Uniform sampling to target_frames
        indices = np.linspace(0, total - 1, self.target_frames, dtype=int)
        sampled_frames = [raw_frames[i] for i in indices]

        keypoint_seq = []
        rgb_seq = []

        for frame in sampled_frames:
            kps = self.extract_landmarks_from_frame(frame)
            keypoint_seq.append(kps)

            # Resize RGB for TimeSformer (224x224)
            resized = cv2.resize(frame, (224, 224))
            rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
            rgb_seq.append(rgb)

        keypoints_array = np.array(keypoint_seq, dtype=np.float32)  # [30, 195]
        rgb_array = np.array(rgb_seq, dtype=np.float32) / 255.0     # [30, 224, 224, 3]

        return rgb_array, keypoints_array
