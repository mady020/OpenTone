import Foundation
import CoreML

// MARK: - Protocol

/// Abstraction for the acoustic model used in pronunciation scoring.
/// Implementations can range from a placeholder heuristic to a full Wav2Vec2 Core ML model.
protocol AcousticModelProvider {
    var modelName: String { get }
    func phonemePosteriors(features: AcousticFeatureMatrix) async throws -> PhonePosteriorMatrix
}

// MARK: - Model Factory

enum AcousticModelFactory {
    /// Returns the best available acoustic model.
    /// Tries Core ML models in order of preference, falls back to placeholder.
    static func bestAvailable() -> AcousticModelProvider {
        // Try Wav2Vec2-based Core ML model first
        if let wav2vec = try? Wav2Vec2AcousticModel() {
            print("[AcousticModel] Using Wav2Vec2 Core ML model")
            return wav2vec
        }

        // Try generic pronunciation model
        let coreMLCandidates = [
            "PronunciationAcousticModel",
            "PhoneClassifier",
            "PronunciationPhoneClassifier"
        ]

        for name in coreMLCandidates {
            if let model = try? GenericCoreMLAcousticModel(modelName: name) {
                print("[AcousticModel] Using Core ML model: \(name)")
                return model
            }
        }

        print("[AcousticModel] No Core ML model found, using placeholder")
        return PlaceholderAcousticModel()
    }
}

// MARK: - Wav2Vec2 Core ML Model

/// Wraps a Wav2Vec2 model converted to Core ML format.
/// Expected model input: MultiArray of audio features [1, frames, feature_dim]
/// Expected model output: MultiArray of phone posteriors [1, frames, 39]
final class Wav2Vec2AcousticModel: AcousticModelProvider {
    let modelName = "Wav2Vec2"
    private let model: MLModel

    init() throws {
        guard let url = Bundle.main.url(forResource: "Wav2Vec2PhoneClassifier", withExtension: "mlmodelc") else {
            throw AcousticModelError.modelNotFound("Wav2Vec2PhoneClassifier")
        }
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        self.model = try MLModel(contentsOf: url, configuration: config)
    }

    func phonemePosteriors(features: AcousticFeatureMatrix) async throws -> PhonePosteriorMatrix {
        let frameCount = features.frameCount
        let featureDim = features.featureDim
        let phoneCount = ARPAPhone.phoneCount

        // Build input MLMultiArray: shape [1, frameCount, featureDim]
        let inputShape = [1, frameCount, featureDim] as [NSNumber]
        let inputArray = try MLMultiArray(shape: inputShape, dataType: .float32)

        for f in 0..<frameCount {
            for d in 0..<featureDim {
                let idx = [0, f, d] as [NSNumber]
                inputArray[idx] = NSNumber(value: features.features[f][d])
            }
        }

        let inputProvider = try MLDictionaryFeatureProvider(dictionary: [
            "audio_features": MLFeatureValue(multiArray: inputArray)
        ])

        let prediction = try await model.prediction(from: inputProvider)

        // Parse output posteriors
        guard let outputArray = prediction.featureValue(for: "phone_posteriors")?.multiArrayValue else {
            throw AcousticModelError.invalidOutput
        }

        var posteriors: [[Float]] = []
        for f in 0..<frameCount {
            var row = [Float](repeating: 0, count: phoneCount)
            for p in 0..<phoneCount {
                let idx = [0, f, p] as [NSNumber]
                row[p] = outputArray[idx].floatValue
            }
            // Apply softmax normalization
            row = softmax(row)
            posteriors.append(row)
        }

        return PhonePosteriorMatrix(
            posteriors: posteriors,
            frameCount: frameCount,
            phoneCount: phoneCount
        )
    }

    private func softmax(_ input: [Float]) -> [Float] {
        let maxVal = input.max() ?? 0
        let exps = input.map { exp($0 - maxVal) }
        let sum = exps.reduce(0, +)
        return exps.map { $0 / max(sum, 1e-10) }
    }
}

// MARK: - Generic Core ML Model

/// Wraps any Core ML model with compatible input/output for phone classification.
final class GenericCoreMLAcousticModel: AcousticModelProvider {
    let modelName: String
    private let model: MLModel

    init(modelName: String) throws {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw AcousticModelError.modelNotFound(modelName)
        }
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        self.model = try MLModel(contentsOf: url, configuration: config)
        self.modelName = modelName
    }

    func phonemePosteriors(features: AcousticFeatureMatrix) async throws -> PhonePosteriorMatrix {
        let frameCount = features.frameCount
        let featureDim = features.featureDim
        let phoneCount = ARPAPhone.phoneCount

        var posteriors: [[Float]] = []

        // Process frame-by-frame for generic models
        for f in 0..<frameCount {
            let inputArray = try MLMultiArray(shape: [featureDim as NSNumber], dataType: .float32)
            for d in 0..<featureDim {
                inputArray[d] = NSNumber(value: features.features[f][d])
            }

            let inputProvider = try MLDictionaryFeatureProvider(dictionary: [
                "features": MLFeatureValue(multiArray: inputArray)
            ])

            let prediction = try await model.prediction(from: inputProvider)

            var row = [Float](repeating: 1.0 / Float(phoneCount), count: phoneCount)

            if let outputArray = prediction.featureValue(for: "posteriors")?.multiArrayValue {
                for p in 0..<min(phoneCount, outputArray.count) {
                    row[p] = outputArray[p].floatValue
                }
            } else if let probDict = prediction.featureValue(for: "phoneProbability")?.dictionaryValue {
                for phone in ARPAPhone.allCases {
                    if let prob = probDict[phone.rawValue as NSObject] as? Double {
                        row[phone.phoneIndex] = Float(prob)
                    }
                }
            }

            posteriors.append(row)
        }

        return PhonePosteriorMatrix(
            posteriors: posteriors,
            frameCount: frameCount,
            phoneCount: phoneCount
        )
    }
}

// MARK: - Placeholder Acoustic Model

/// Heuristic-based model that derives phone posteriors from spectral features.
/// Functional for pipeline testing but not ML-trained.
/// Replace with a real Core ML model for production accuracy.
final class PlaceholderAcousticModel: AcousticModelProvider {
    let modelName = "Placeholder (spectral heuristic)"

    func phonemePosteriors(features: AcousticFeatureMatrix) async throws -> PhonePosteriorMatrix {
        let phoneCount = ARPAPhone.phoneCount
        var posteriors: [[Float]] = []

        for f in 0..<features.frameCount {
            let frame = features.features[f]
            let row = estimatePosteriorsFromSpectrum(frame: frame, phoneCount: phoneCount)
            posteriors.append(row)
        }

        return PhonePosteriorMatrix(
            posteriors: posteriors,
            frameCount: features.frameCount,
            phoneCount: phoneCount
        )
    }

    /// Derive rough phone posteriors from spectral shape.
    /// This is a simplified heuristic — not a replacement for a trained model.
    private func estimatePosteriorsFromSpectrum(frame: [Float], phoneCount: Int) -> [Float] {
        var posteriors = [Float](repeating: 0, count: phoneCount)
        let melBands = min(frame.count - 1, 40)
        guard melBands > 0 else {
            return [Float](repeating: 1.0 / Float(phoneCount), count: phoneCount)
        }

        let energy = frame.last ?? -60.0
        let isVoiced = energy > -40.0

        // Compute spectral centroid (rough frequency center)
        var weightedSum: Float = 0
        var totalWeight: Float = 0
        for b in 0..<melBands {
            let linearEnergy = exp(frame[b])
            weightedSum += Float(b) * linearEnergy
            totalWeight += linearEnergy
        }
        let centroid = totalWeight > 0 ? weightedSum / totalWeight : Float(melBands) / 2.0
        let normalizedCentroid = centroid / Float(melBands)

        // Spectral slope (high vs low energy ratio)
        let lowEnergy = frame[0..<(melBands / 3)].reduce(0, +) / Float(melBands / 3)
        let highEnergy = frame[(2 * melBands / 3)..<melBands].reduce(0, +) / Float(melBands / 3)
        let slope = highEnergy - lowEnergy

        // Spectral flatness (tonal vs noisy)
        let linearFrame = frame[0..<melBands].map { exp($0) }
        let geometricMean = exp(linearFrame.map { log(max($0, 1e-10)) }.reduce(0, +) / Float(melBands))
        let arithmeticMean = linearFrame.reduce(0, +) / Float(melBands)
        let flatness = arithmeticMean > 0 ? geometricMean / arithmeticMean : 0

        // Assign heuristic probabilities based on spectral properties
        for phone in ARPAPhone.allCases {
            let idx = phone.phoneIndex
            var prob: Float = 0.01  // baseline

            if phone.isVowel {
                if isVoiced {
                    prob += 0.15
                    // Lower centroid = more open vowels
                    if normalizedCentroid < 0.4 { prob += phone == .AA || phone == .AO ? 0.1 : 0.02 }
                    // Higher centroid = front vowels
                    if normalizedCentroid > 0.5 { prob += phone == .IY || phone == .EY ? 0.1 : 0.02 }
                }
            } else if phone.isFricative {
                // Fricatives: high energy in upper bands, noise-like (high flatness)
                if flatness > 0.3 && slope > 0 {
                    prob += 0.12
                    if phone == .S || phone == .SH { prob += normalizedCentroid > 0.6 ? 0.08 : 0.02 }
                    if phone == .F || phone == .TH { prob += normalizedCentroid > 0.5 ? 0.05 : 0.01 }
                }
            } else if phone.isStop {
                // Stops: low energy (closure) or burst
                if !isVoiced {
                    prob += 0.08
                }
            } else if phone.isNasal {
                // Nasals: low centroid, voiced
                if isVoiced && normalizedCentroid < 0.35 {
                    prob += 0.12
                }
            } else {
                // Liquids, glides
                if isVoiced {
                    prob += 0.06
                }
            }

            posteriors[idx] = prob
        }

        // Normalize to sum to 1
        let total = posteriors.reduce(0, +)
        if total > 0 {
            posteriors = posteriors.map { $0 / total }
        }

        return posteriors
    }
}

// MARK: - Errors

enum AcousticModelError: LocalizedError {
    case modelNotFound(String)
    case invalidOutput
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name): return "Acoustic model '\(name)' not found in app bundle"
        case .invalidOutput: return "Model produced invalid output format"
        case .processingFailed(let msg): return "Acoustic processing failed: \(msg)"
        }
    }
}
