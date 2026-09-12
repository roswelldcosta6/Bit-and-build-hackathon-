"""
SignBridge TFLite Export & Validation Pipeline
Converts trained Keras model into optimized on-device TFLite model,
validates inference accuracy, generates labels_bilingual.json, and syncs assets across the project.
"""

import os
import sys
import json
import shutil

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

import numpy as np
import tensorflow as tf

from vocabulary import CLASSES, BILINGUAL_DICT, NUM_CLASSES
from dataset import generate_sequence


def export_and_validate(keras_model_path: str = "best_model.keras",
                        tflite_output_path: str = "model.tflite",
                        labels_output_path: str = "labels_bilingual.json"):
    """
    Convert Keras model to pure Builtin TFLite with quantization, verify inference, and export labels.
    """
    print("=" * 70)
    print("Exporting SignBridge Model to Pure Builtin TFLite")
    print("=" * 70)

    # 1. Load Keras Model
    model = tf.keras.models.load_model(keras_model_path)
    print(f"Loaded Keras model from {keras_model_path}")

    # 2. Convert to TFLite (Pure TFLITE_BUILTINS only, no Flex ops)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]

    tflite_model = converter.convert()

    # Save TFLite model
    with open(tflite_output_path, "wb") as f:
        f.write(tflite_model)
    
    file_size_kb = os.path.getsize(tflite_output_path) / 1024.0
    print(f"✅ TFLite model saved to: {tflite_output_path} ({file_size_kb:.2f} KB)")

    # 3. Export Bilingual Labels JSON
    labels_data = {}
    for class_name in CLASSES:
        label_key = class_name.upper().replace(" ", "_")
        bilingual_info = BILINGUAL_DICT.get(class_name, {"en": class_name, "hi": class_name})
        labels_data[label_key] = bilingual_info

    with open(labels_output_path, "w", encoding="utf-8") as f:
        json.dump(labels_data, f, ensure_ascii=False, indent=2)

    print(f"✅ Bilingual labels saved to: {labels_output_path} ({len(labels_data)} classes)")

    # 4. Validate TFLite Inference vs Keras Model
    print("\n🔍 Validating TFLite Model Inference Accuracy...")
    interpreter = tf.lite.Interpreter(model_path=tflite_output_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"  TFLite Input Shape:  {input_details[0]['shape']}")
    print(f"  TFLite Output Shape: {output_details[0]['shape']}")

    # Test with sample classes
    test_classes = ["Help", "Doctor", "Eat", "A", "5", "Hospital", "Hello", "Thank You", "Emergency", "Pain"]
    matches = 0
    
    for cls in test_classes:
        sample_input = generate_sequence(cls, augment=False)
        sample_batch = np.expand_dims(sample_input, axis=0).astype(np.float32)

        # Keras prediction
        keras_pred = model.predict(sample_batch, verbose=0)[0]
        keras_idx = np.argmax(keras_pred)
        keras_conf = keras_pred[keras_idx]

        # TFLite prediction
        interpreter.set_tensor(input_details[0]["index"], sample_batch)
        interpreter.invoke()
        tflite_pred = interpreter.get_tensor(output_details[0]["index"])[0]
        tflite_idx = np.argmax(tflite_pred)
        tflite_conf = tflite_pred[tflite_idx]

        is_match = (keras_idx == tflite_idx)
        if is_match:
            matches += 1

        print(f"  [{cls:10s}] Target: {cls:10s} | Keras: {CLASSES[keras_idx]:10s} ({keras_conf:.2f}) | TFLite: {CLASSES[tflite_idx]:10s} ({tflite_conf:.2f}) | Match: {'✅' if is_match else '❌'}")

    print(f"\nValidation Result: {matches}/{len(test_classes)} sample test inferences matched.")

    # 5. Sync Artifacts to App and Backend
    target_locations = [
        r"C:\Users\ferna\OneDrive\Desktop\bit\signbridge\assets",
        r"C:\Users\ferna\OneDrive\Desktop\bit\Bit-and-build-hackathon-\app\assets",
        r"C:\Users\ferna\OneDrive\Desktop\bit\Bit-and-build-hackathon-\backend\models"
    ]

    print("\n🚀 Syncing Model & Labels across project assets...")
    for loc in target_locations:
        os.makedirs(loc, exist_ok=True)
        shutil.copy2(tflite_output_path, os.path.join(loc, "model.tflite"))
        shutil.copy2(labels_output_path, os.path.join(loc, "labels_bilingual.json"))
        print(f"  -> Synced to: {loc}")

    print("\n🎉 Complete ML pipeline finished successfully!")


if __name__ == "__main__":
    export_and_validate()
