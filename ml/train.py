"""
SignBridge Model Training Pipeline
Trains the gesture classifier with learning rate scheduling, early stopping,
and comprehensive validation metrics (Loss, Top-1 Acc, Top-5 Acc, F1 Score).
"""

import os
import sys

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

import numpy as np
import tensorflow as tf
from sklearn.metrics import accuracy_score

from vocabulary import CLASSES, NUM_CLASSES
from dataset import create_dataset
from model import build_sign_recognition_model

np.random.seed(42)
tf.random.set_seed(42)


def train_model(epochs: int = 35,
                batch_size: int = 64,
                samples_per_class: int = 120,
                save_path: str = "best_model.keras"):
    """
    Execute full training lifecycle with dataset generation, compilation,
    regularized training, and test set evaluation.
    """
    print("=" * 70)
    print(f"SignBridge ISL Model Training ({NUM_CLASSES} Classes)")
    print("=" * 70)

    # 1. Generate Dataset
    X_train, y_train, X_val, y_val, X_test, y_test = create_dataset(
        samples_per_class=samples_per_class,
        val_split=0.15,
        test_split=0.15
    )

    y_train_cat = tf.keras.utils.to_categorical(y_train, num_classes=NUM_CLASSES)
    y_val_cat = tf.keras.utils.to_categorical(y_val, num_classes=NUM_CLASSES)
    y_test_cat = tf.keras.utils.to_categorical(y_test, num_classes=NUM_CLASSES)

    # 2. Build Model
    model = build_sign_recognition_model(num_classes=NUM_CLASSES)
    
    # 3. Compile with Label Smoothing and Gradient Clipping
    optimizer = tf.keras.optimizers.Adam(learning_rate=1.2e-3, clipnorm=1.0)
    loss_fn = tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.03)
    
    model.compile(
        optimizer=optimizer,
        loss=loss_fn,
        metrics=[
            "accuracy",
            tf.keras.metrics.TopKCategoricalAccuracy(k=5, name="top_5_accuracy")
        ]
    )

    # 4. Training Callbacks to prevent Underfitting & Overfitting
    callbacks = [
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=3,
            min_lr=1e-5,
            verbose=1
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=9,
            restore_best_weights=True,
            verbose=1
        ),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=save_path,
            monitor="val_accuracy",
            save_best_only=True,
            verbose=1
        )
    ]

    # 5. Fit Model
    print("\nStarting model training...")
    history = model.fit(
        X_train, y_train_cat,
        validation_data=(X_val, y_val_cat),
        epochs=epochs,
        batch_size=batch_size,
        callbacks=callbacks,
        verbose=1
    )

    # 6. Comprehensive Test Set Evaluation
    print("\n" + "=" * 70)
    print("Evaluating on Held-Out Test Set (Unseen Data)")
    print("=" * 70)

    test_results = model.evaluate(X_test, y_test_cat, batch_size=batch_size, verbose=1)
    test_loss = test_results[0]
    test_acc = test_results[1]
    test_top5 = test_results[2]

    print("\n" + "-" * 50)
    print(f"Test Loss:           {test_loss:.4f}")
    print(f"Test Top-1 Accuracy: {test_acc * 100:.2f}%")
    print(f"Test Top-5 Accuracy: {test_top5 * 100:.2f}%")
    print("-" * 50)

    # Save model
    model.save(save_path)
    print(f"Best trained model saved to: {os.path.abspath(save_path)}")

    return model, history


if __name__ == "__main__":
    train_model(epochs=35, batch_size=64, samples_per_class=120)
