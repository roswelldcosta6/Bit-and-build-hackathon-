"""
SignBridge Dataset & Landmark Kinematics Generator
Generates distinctive, biomechanically realistic 30-frame x 63-keypoint gesture sequences
for all 149 ISL classes, with full kinematic diversity and data augmentation.
"""

import sys
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

import math
import numpy as np
from typing import Tuple, List, Dict
from vocabulary import CLASSES, NUM_CLASSES, LABEL_TO_IDX

SEQUENCE_LENGTH = 30
NUM_LANDMARKS = 21
FEATURE_DIM = 63


def _rotate_3d(coords: np.ndarray, angle_x: float, angle_y: float, angle_z: float) -> np.ndarray:
    """Rotate 3D coordinates (N, 3) around center."""
    center = coords.mean(axis=0, keepdims=True)
    c = coords - center
    
    cx, sx = math.cos(angle_x), math.sin(angle_x)
    rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]], dtype=np.float32)
    
    cy, sy = math.cos(angle_y), math.sin(angle_y)
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]], dtype=np.float32)
    
    cz, sz = math.cos(angle_z), math.sin(angle_z)
    rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]], dtype=np.float32)
    
    return (c @ (rz @ ry @ rx).T) + center


# Define hand posture archetypes [Pinky, Index, Thumb] offsets from wrist
HAND_POSTURES = {
    "open_palm":  [[-0.04, -0.09, 0.00], [0.00, -0.11, 0.00], [0.04, -0.06, 0.02]],
    "fist":       [[-0.02, -0.03, 0.01], [0.00, -0.04, 0.02], [0.02, -0.03, 0.03]],
    "index_point":[[-0.02, -0.03, 0.01], [0.00, -0.12, 0.00], [0.02, -0.03, 0.02]],
    "two_fingers":[[-0.02, -0.03, 0.01], [0.01, -0.11, 0.00], [0.03, -0.05, 0.01]],
    "three_fin":  [[-0.03, -0.07, 0.00], [0.01, -0.10, 0.00], [0.03, -0.04, 0.02]],
    "four_fin":   [[-0.04, -0.09, 0.00], [0.00, -0.10, 0.00], [0.02, -0.03, 0.03]],
    "thumbs_up":  [[-0.02, -0.03, 0.01], [0.00, -0.04, 0.02], [0.04, -0.10, 0.02]],
    "pinch":      [[-0.02, -0.03, 0.01], [0.01, -0.07, 0.01], [0.01, -0.07, 0.01]],
    "claw":       [[-0.03, -0.06, 0.03], [0.00, -0.07, 0.04], [0.03, -0.05, 0.03]],
    "c_shape":    [[-0.03, -0.06, 0.02], [0.00, -0.08, 0.03], [0.03, -0.03, 0.01]],
    "flat_hand":  [[-0.03, -0.08, 0.00], [0.00, -0.09, 0.00], [0.03, -0.04, 0.01]],
    "l_shape":    [[-0.02, -0.03, 0.01], [0.00, -0.11, 0.00], [0.06, -0.03, 0.01]],
    "v_peace":    [[-0.02, -0.03, 0.01], [0.02, -0.11, 0.00], [0.02, -0.03, 0.02]],
}


def get_base_kinematics(class_name: str, frame_idx: int, total_frames: int = SEQUENCE_LENGTH) -> np.ndarray:
    """
    Computes precise 3D keypoint configuration for a class at time t in [0, 1].
    """
    t = frame_idx / float(total_frames - 1)
    stroke = math.sin(t * math.pi)  # Bell envelope
    cycle = math.sin(t * math.pi * 2)
    
    landmarks = np.zeros((21, 3), dtype=np.float32)
    
    # Body Anchors
    landmarks[12] = [0.50, 0.20, 0.0]         # Nose
    landmarks[13] = [0.46, 0.18, 0.0]         # LeftEye
    landmarks[14] = [0.54, 0.18, 0.0]         # RightEye
    landmarks[15] = [0.42, 0.20, 0.05]        # LeftEar
    landmarks[16] = [0.58, 0.20, 0.05]        # RightEar
    landmarks[11] = [0.38, 0.35, 0.0]         # LeftShoulder
    landmarks[5]  = [0.62, 0.35, 0.0]         # RightShoulder
    landmarks[10] = [0.34, 0.52, 0.05]        # LeftElbow
    landmarks[4]  = [0.66, 0.52, 0.05]        # RightElbow
    landmarks[17] = [0.42, 0.75, 0.0]         # LeftHip
    landmarks[18] = [0.58, 0.75, 0.0]         # RightHip
    landmarks[19] = [0.43, 0.90, 0.0]         # LeftKnee
    landmarks[20] = [0.57, 0.90, 0.0]         # RightKnee
    
    class_idx = LABEL_TO_IDX[class_name]
    
    # 1. NUMBERS (0-9)
    if class_name.isdigit():
        num = int(class_name)
        postures = ["fist", "index_point", "two_fingers", "three_fin", "four_fin", 
                    "open_palm", "thumbs_up", "pinch", "claw", "c_shape"]
        hand_type = postures[num % len(postures)]
        offsets = HAND_POSTURES[hand_type]
        
        r_wrist = np.array([0.58 + 0.02 * stroke, 0.46 - 0.04 * stroke, -0.15], dtype=np.float32)
        l_wrist = np.array([0.40, 0.65, 0.0], dtype=np.float32)
        
    # 2. ALPHABET (A-Z)
    elif len(class_name) == 1 and class_name.isalpha():
        char_idx = ord(class_name.upper()) - ord('A')
        posture_keys = list(HAND_POSTURES.keys())
        hand_type = posture_keys[char_idx % len(posture_keys)]
        offsets = HAND_POSTURES[hand_type]
        
        # Spatial quadrant based on alphabet group
        quad_x = 0.55 + 0.08 * math.sin((char_idx / 26.0) * math.pi * 2)
        quad_y = 0.44 + 0.08 * math.cos((char_idx / 26.0) * math.pi * 2)
        r_wrist = np.array([quad_x, quad_y, -0.12 - 0.04 * stroke], dtype=np.float32)
        l_wrist = np.array([0.42, 0.62, 0.0], dtype=np.float32)

    # 3. WORDS & EMERGENCY
    else:
        # Kinematic Profiles tailored to ISL semantics:
        if class_name in ["Help", "Emergency", "Danger"]:
            offsets = HAND_POSTURES["flat_hand"]
            r_wrist = np.array([0.56 + 0.08 * stroke, 0.52 - 0.22 * stroke, -0.10 - 0.18 * stroke])
            l_wrist = np.array([0.44 - 0.08 * stroke, 0.52 - 0.22 * stroke, -0.10 - 0.18 * stroke])
            
        elif class_name in ["Hospital", "Doctor", "Medicine", "Ambulance", "Nurse"]:
            offsets = HAND_POSTURES["two_fingers"]
            r_wrist = np.array([0.50 + 0.08 * cycle, 0.36 + 0.06 * stroke, -0.08 - 0.10 * stroke])
            l_wrist = np.array([0.42, 0.55 + 0.05 * stroke, 0.0])
            
        elif class_name in ["Pain", "Sick", "Injury", "Accident", "Fever"]:
            offsets = HAND_POSTURES["pinch"]
            r_wrist = np.array([0.52 + 0.04 * cycle, 0.42 + 0.10 * stroke, -0.10 - 0.10 * stroke])
            l_wrist = np.array([0.48 - 0.04 * cycle, 0.42 + 0.10 * stroke, -0.10 - 0.10 * stroke])
            
        elif class_name in ["Hello", "Bye", "Welcome", "Good", "Great"]:
            offsets = HAND_POSTURES["open_palm"]
            r_wrist = np.array([0.60 + 0.10 * cycle, 0.30 - 0.08 * stroke, -0.14 - 0.06 * stroke])
            l_wrist = np.array([0.40, 0.65, 0.0])
            
        elif class_name in ["Thank", "Thank You"]:
            offsets = HAND_POSTURES["flat_hand"]
            # Chin to forward extension
            r_wrist = np.array([0.52, 0.28 + 0.18 * stroke, -0.05 - 0.22 * stroke])
            l_wrist = np.array([0.40, 0.65, 0.0])

        elif class_name in ["ME", "My", "Self", "Yourself", "You", "Us", "We"]:
            offsets = HAND_POSTURES["index_point"]
            target_x = 0.50 if class_name in ["ME", "My", "Self"] else 0.50 + 0.10 * stroke
            target_y = 0.38 if class_name in ["ME", "My", "Self"] else 0.48 - 0.10 * stroke
            r_wrist = np.array([target_x, target_y, -0.05 - 0.15 * stroke])
            l_wrist = np.array([0.40, 0.65, 0.0])

        elif class_name in ["What", "When", "Where", "Which", "Who", "Why", "How"]:
            offsets = HAND_POSTURES["open_palm"]
            r_wrist = np.array([0.62 + 0.08 * stroke, 0.48 + 0.05 * stroke, -0.12])
            l_wrist = np.array([0.38 - 0.08 * stroke, 0.48 + 0.05 * stroke, -0.12])

        elif class_name in ["Time", "Day", "Now", "Today", "Tomorrow", "After", "Before"]:
            offsets = HAND_POSTURES["index_point"]
            r_wrist = np.array([0.44 + 0.04 * stroke, 0.52 - 0.08 * stroke, -0.08])
            l_wrist = np.array([0.42, 0.54, -0.05])

        elif class_name in ["Eat", "Food", "Water", "Wash"]:
            offsets = HAND_POSTURES["pinch"]
            r_wrist = np.array([0.50, 0.30 - 0.08 * stroke, -0.06 - 0.08 * stroke])
            l_wrist = np.array([0.40, 0.65, 0.0])

        elif class_name in ["Work", "Study", "Learn", "School", "College", "Book"]:
            offsets = HAND_POSTURES["flat_hand"]
            r_wrist = np.array([0.54 + 0.06 * cycle, 0.48 - 0.08 * stroke, -0.12])
            l_wrist = np.array([0.46 - 0.06 * cycle, 0.48 - 0.08 * stroke, -0.12])
            
        else:
            # Deterministic unique signature for remaining vocabulary
            phi = (class_idx / float(NUM_CLASSES)) * math.pi * 4.0
            freq = 1.0 + (class_idx % 4)
            posture_keys = list(HAND_POSTURES.keys())
            offsets = HAND_POSTURES[posture_keys[class_idx % len(posture_keys)]]
            
            rx = 0.56 + 0.12 * math.sin(t * math.pi * freq + phi) * stroke
            ry = 0.46 - 0.14 * math.cos(t * math.pi * freq) * stroke
            rz = -0.10 - 0.12 * stroke
            r_wrist = np.array([rx, ry, rz], dtype=np.float32)
            l_wrist = np.array([0.40 + 0.04 * math.cos(phi) * stroke, 0.62, 0.0], dtype=np.float32)

    # Assign hand landmarks
    landmarks[0] = r_wrist
    landmarks[1] = r_wrist + offsets[0]
    landmarks[2] = r_wrist + offsets[1]
    landmarks[3] = r_wrist + offsets[2]

    landmarks[6] = l_wrist
    landmarks[7] = l_wrist + [0.03, -0.04, 0.0]
    landmarks[8] = l_wrist + [0.00, -0.05, 0.0]
    landmarks[9] = l_wrist + [-0.03, -0.03, 0.0]

    return landmarks


def generate_sequence(class_name: str, augment: bool = True) -> np.ndarray:
    """
    Generate an augmented 30-frame sequence (30, 63) for a class.
    """
    sequence = np.zeros((SEQUENCE_LENGTH, NUM_LANDMARKS, 3), dtype=np.float32)
    
    if augment:
        rot_x = np.random.uniform(-0.12, 0.12)
        rot_y = np.random.uniform(-0.12, 0.12)
        rot_z = np.random.uniform(-0.12, 0.12)
        scale = np.random.uniform(0.90, 1.10)
        shift_x = np.random.uniform(-0.04, 0.04)
        shift_y = np.random.uniform(-0.04, 0.04)
        shift_z = np.random.uniform(-0.03, 0.03)
        noise_std = np.random.uniform(0.006, 0.015)
        warp_power = np.random.uniform(0.88, 1.14)
    else:
        rot_x, rot_y, rot_z = 0.0, 0.0, 0.0
        scale = 1.0
        shift_x, shift_y, shift_z = 0.0, 0.0, 0.0
        noise_std = 0.003
        warp_power = 1.0

    time_indices = np.linspace(0, 1, SEQUENCE_LENGTH)
    if augment:
        time_indices = np.power(time_indices, warp_power)
    
    for i, t in enumerate(time_indices):
        frame_idx = int(round(t * (SEQUENCE_LENGTH - 1)))
        frame_idx = min(max(frame_idx, 0), SEQUENCE_LENGTH - 1)
        
        frame = get_base_kinematics(class_name, frame_idx, SEQUENCE_LENGTH)
        frame = _rotate_3d(frame, rot_x, rot_y, rot_z)
        frame = frame * scale + np.array([shift_x, shift_y, shift_z], dtype=np.float32)
        
        # Sensor jitter
        noise = np.random.normal(0, noise_std, frame.shape).astype(np.float32)
        frame += noise
        
        frame[:, 0] = np.clip(frame[:, 0], 0.0, 1.0)
        frame[:, 1] = np.clip(frame[:, 1], 0.0, 1.0)
        frame[:, 2] = np.clip(frame[:, 2], -1.0, 1.0)
        sequence[i] = frame

    # Random frame interpolation / dropout
    if augment and np.random.random() < 0.20:
        drop_idx = np.random.randint(1, SEQUENCE_LENGTH - 1)
        sequence[drop_idx] = (sequence[drop_idx - 1] + sequence[drop_idx + 1]) * 0.5

    return sequence.reshape(SEQUENCE_LENGTH, FEATURE_DIM)


def create_dataset(samples_per_class: int = 120,
                   val_split: float = 0.15,
                   test_split: float = 0.15) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Generate balanced training, validation, and test sets.
    """
    X_train, y_train = [], []
    X_val, y_val = [], []
    X_test, y_test = [], []

    train_samples = int(samples_per_class * (1.0 - val_split - test_split))
    val_samples = int(samples_per_class * val_split)
    test_samples = samples_per_class - train_samples - val_samples

    print(f"Generating ISL Dataset:")
    print(f"  Classes: {NUM_CLASSES}")
    print(f"  Samples per class: {train_samples} train, {val_samples} val, {test_samples} test (Total: {samples_per_class * NUM_CLASSES})")

    for class_idx, class_name in enumerate(CLASSES):
        for _ in range(train_samples):
            X_train.append(generate_sequence(class_name, augment=True))
            y_train.append(class_idx)

        for _ in range(val_samples):
            X_val.append(generate_sequence(class_name, augment=True))
            y_val.append(class_idx)

        for _ in range(test_samples):
            X_test.append(generate_sequence(class_name, augment=False))
            y_test.append(class_idx)

    X_train = np.array(X_train, dtype=np.float32)
    y_train = np.array(y_train, dtype=np.int32)
    X_val = np.array(X_val, dtype=np.float32)
    y_val = np.array(y_val, dtype=np.int32)
    X_test = np.array(X_test, dtype=np.float32)
    y_test = np.array(y_test, dtype=np.int32)

    perm = np.random.permutation(len(X_train))
    X_train, y_train = X_train[perm], y_train[perm]

    print(f"Dataset summary:")
    print(f"  Train: {X_train.shape} | Val: {X_val.shape} | Test: {X_test.shape}")

    return X_train, y_train, X_val, y_val, X_test, y_test
