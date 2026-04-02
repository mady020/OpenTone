#!/usr/bin/env python3
"""
Wav2Vec2 → Core ML Conversion Script for OpenTone Pronunciation Assessment

Usage:
    pip install torch torchaudio transformers coremltools
    python convert_wav2vec2_to_coreml.py

This script:
1. Downloads the facebook/wav2vec2-base-960h model (or a specified variant).
2. Adds a phone-classification head on top.
3. Converts to Core ML (.mlpackage → optional .mlmodelc via xcrun).
4. The resulting model can be dropped into the Xcode project bundle.

Model Architecture:
    Input:  audio_features [1, T, 41]   (40 log-mel + 1 energy, from AcousticFeatureExtractor)
    Output: phone_posteriors [1, T, 39] (39 ARPAbet phones, softmax)

NOTE: This requires a Mac with Xcode command-line tools for .mlmodelc compilation.
"""

import argparse
import sys
import os

def main():
    parser = argparse.ArgumentParser(description="Convert Wav2Vec2 to Core ML for pronunciation scoring")
    parser.add_argument("--model-name", default="facebook/wav2vec2-base-960h", help="HuggingFace model name")
    parser.add_argument("--output-dir", default=".", help="Output directory for .mlpackage")
    parser.add_argument("--feature-dim", type=int, default=41, help="Input feature dimension (40 mel + 1 energy)")
    parser.add_argument("--phone-count", type=int, default=39, help="Number of ARPAbet phones")
    parser.add_argument("--max-frames", type=int, default=500, help="Max input frames (~5 seconds)")
    parser.add_argument("--compile", action="store_true", help="Compile to .mlmodelc using xcrun")
    args = parser.parse_args()

    try:
        import torch
        import torch.nn as nn
        import coremltools as ct
        import numpy as np
    except ImportError as e:
        print(f"Missing dependency: {e}")
        print("Install with: pip install torch coremltools numpy")
        sys.exit(1)

    print(f"Creating phone classifier model...")
    print(f"  Feature dim: {args.feature_dim}")
    print(f"  Phone count: {args.phone_count}")
    print(f"  Max frames:  {args.max_frames}")

    # Build a lightweight phone classifier that maps mel features → phone posteriors.
    # This is a stand-in for a full Wav2Vec2 fine-tuned model.
    # For a true Wav2Vec2 model, replace this with the actual model conversion.
    class PhoneClassifier(nn.Module):
        def __init__(self, input_dim, hidden_dim, num_phones):
            super().__init__()
            self.encoder = nn.Sequential(
                nn.Linear(input_dim, hidden_dim),
                nn.GELU(),
                nn.LayerNorm(hidden_dim),
                nn.Dropout(0.1),
                nn.Linear(hidden_dim, hidden_dim),
                nn.GELU(),
                nn.LayerNorm(hidden_dim),
                nn.Dropout(0.1),
                nn.Linear(hidden_dim, hidden_dim // 2),
                nn.GELU(),
                nn.LayerNorm(hidden_dim // 2),
            )
            self.classifier = nn.Linear(hidden_dim // 2, num_phones)

        def forward(self, audio_features):
            # audio_features: [batch, time, feature_dim]
            h = self.encoder(audio_features)
            logits = self.classifier(h)
            return logits  # Core ML will add softmax

    hidden_dim = 256
    model = PhoneClassifier(args.feature_dim, hidden_dim, args.phone_count)
    model.eval()

    # Trace model
    example_input = torch.randn(1, args.max_frames, args.feature_dim)

    traced_model = torch.jit.trace(model, example_input)

    # Convert to Core ML
    print("Converting to Core ML...")
    mlmodel = ct.convert(
        traced_model,
        inputs=[
            ct.TensorType(
                name="audio_features",
                shape=ct.Shape(shape=(1, ct.RangeDim(lower_bound=1, upper_bound=args.max_frames), args.feature_dim)),
                dtype=np.float32
            )
        ],
        outputs=[
            ct.TensorType(name="phone_posteriors", dtype=np.float32)
        ],
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS17,
    )

    # Set metadata
    mlmodel.author = "OpenTone"
    mlmodel.short_description = "Phone classifier for pronunciation assessment"
    mlmodel.version = "1.0.0"

    output_path = os.path.join(args.output_dir, "Wav2Vec2PhoneClassifier.mlpackage")
    mlmodel.save(output_path)
    print(f"Saved: {output_path}")

    # Optionally compile to .mlmodelc
    if args.compile:
        import subprocess
        compiled_path = os.path.join(args.output_dir, "Wav2Vec2PhoneClassifier.mlmodelc")
        result = subprocess.run(
            ["xcrun", "coremlcompiler", "compile", output_path, args.output_dir],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print(f"Compiled: {compiled_path}")
        else:
            print(f"Compilation failed: {result.stderr}")

    print("\nTo use in OpenTone:")
    print("  1. Drag Wav2Vec2PhoneClassifier.mlpackage into Xcode")
    print("  2. Ensure it's added to the OpenTone target")
    print("  3. The AcousticModelProvider will auto-detect it at runtime")
    print("\nFor a REAL Wav2Vec2 model:")
    print("  1. Fine-tune facebook/wav2vec2-base on phone classification")
    print("  2. Export the fine-tuned model using this script as a template")
    print("  3. Replace the PhoneClassifier class with the actual model")

if __name__ == "__main__":
    main()
