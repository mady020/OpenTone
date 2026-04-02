import Foundation
import Accelerate

/// Extracts acoustic features from raw audio using Apple's Accelerate framework.
/// Produces log-mel spectrograms, energy, and pitch features for the pronunciation pipeline.
final class AcousticFeatureExtractor {

    struct Config {
        var sampleRate: Int = 16000
        var fftSize: Int = 512
        var hopLength: Int = 160        // 10ms at 16kHz
        var nMelBands: Int = 40
        var fMin: Float = 80.0
        var fMax: Float = 7600.0
        var preemphasis: Float = 0.97
        var minPitchHz: Float = 75.0
        var maxPitchHz: Float = 500.0
    }

    private let config: Config
    private let melFilterbank: [[Float]]
    private let fftSetup: vDSP.FFT<DSPSplitComplex>?

    init(config: Config = Config()) {
        self.config = config
        self.melFilterbank = Self.buildMelFilterbank(
            nMelBands: config.nMelBands,
            fftSize: config.fftSize,
            sampleRate: config.sampleRate,
            fMin: config.fMin,
            fMax: config.fMax
        )
        let log2n = vDSP_Length(log2(Float(config.fftSize)))
        self.fftSetup = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)
    }

    // MARK: - Public API

    func extractFeatures(from samples: [Float]) -> AcousticFeatureMatrix {
        let preemphasized = applyPreemphasis(samples)
        let frames = frameSignal(preemphasized)
        var featureRows: [[Float]] = []

        for frame in frames {
            let melSpec = computeLogMelSpectrum(frame: frame)
            let energy = computeEnergy(frame: frame)
            var row = melSpec
            row.append(energy)
            featureRows.append(row)
        }

        return AcousticFeatureMatrix(
            features: featureRows,
            frameCount: featureRows.count,
            featureDim: featureRows.first?.count ?? 0,
            sampleRate: config.sampleRate,
            hopLength: config.hopLength
        )
    }

    /// Extract pitch (F0) contour for prosody analysis via autocorrelation.
    func extractPitchContour(from samples: [Float]) -> [Float?] {
        let frames = frameSignal(samples)
        return frames.map { frame in
            estimatePitch(frame: frame)
        }
    }

    /// Extract per-frame RMS energy for prosody analysis.
    func extractEnergyContour(from samples: [Float]) -> [Float] {
        let frames = frameSignal(samples)
        return frames.map { computeEnergy(frame: $0) }
    }

    // MARK: - Frame Extraction

    private func applyPreemphasis(_ samples: [Float]) -> [Float] {
        guard samples.count > 1 else { return samples }
        var result = [Float](repeating: 0, count: samples.count)
        result[0] = samples[0]
        for i in 1..<samples.count {
            result[i] = samples[i] - config.preemphasis * samples[i - 1]
        }
        return result
    }

    private func frameSignal(_ samples: [Float]) -> [[Float]] {
        let fftSize = config.fftSize
        let hop = config.hopLength
        guard samples.count >= fftSize else { return [] }

        let numFrames = max(1, (samples.count - fftSize) / hop + 1)
        var frames: [[Float]] = []
        frames.reserveCapacity(numFrames)

        let window = buildHannWindow(size: fftSize)

        for i in 0..<numFrames {
            let start = i * hop
            let end = min(start + fftSize, samples.count)
            var frame = Array(samples[start..<end])
            if frame.count < fftSize {
                frame.append(contentsOf: [Float](repeating: 0, count: fftSize - frame.count))
            }
            // Apply window
            vDSP.multiply(frame, window, result: &frame)
            frames.append(frame)
        }

        return frames
    }

    private func buildHannWindow(size: Int) -> [Float] {
        var window = [Float](repeating: 0, count: size)
        vDSP_hann_window(&window, vDSP_Length(size), Int32(vDSP_HANN_NORM))
        return window
    }

    // MARK: - Log-Mel Spectrum

    private func computeLogMelSpectrum(frame: [Float]) -> [Float] {
        let powerSpectrum = computePowerSpectrum(frame: frame)
        return applyMelFilterbank(powerSpectrum: powerSpectrum)
    }

    private func computePowerSpectrum(frame: [Float]) -> [Float] {
        let n = config.fftSize
        let halfN = n / 2

        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        frame.withUnsafeBufferPointer { inputPtr in
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(
                        realp: realPtr.baseAddress!,
                        imagp: imagPtr.baseAddress!
                    )
                    inputPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(halfN))
                    }
                    fftSetup?.forward(input: splitComplex, output: &splitComplex)
                }
            }
        }

        var magnitudes = [Float](repeating: 0, count: halfN)
        realPart.withUnsafeBufferPointer { realPtr in
            imagPart.withUnsafeBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(
                    realp: UnsafeMutablePointer(mutating: realPtr.baseAddress!),
                    imagp: UnsafeMutablePointer(mutating: imagPtr.baseAddress!)
                )
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfN))
            }
        }

        // Normalize
        var scale = Float(n)
        vDSP_vsdiv(magnitudes, 1, &scale, &magnitudes, 1, vDSP_Length(halfN))

        return magnitudes
    }

    private func applyMelFilterbank(powerSpectrum: [Float]) -> [Float] {
        var melEnergies = [Float](repeating: 0, count: config.nMelBands)
        let specLen = min(powerSpectrum.count, melFilterbank.first?.count ?? 0)

        for band in 0..<config.nMelBands {
            var sum: Float = 0
            let filter = melFilterbank[band]
            for k in 0..<specLen {
                sum += powerSpectrum[k] * filter[k]
            }
            // Log compression with floor to avoid log(0)
            melEnergies[band] = log(max(sum, 1e-10))
        }

        return melEnergies
    }

    // MARK: - Energy

    private func computeEnergy(frame: [Float]) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(frame, 1, &rms, vDSP_Length(frame.count))
        return 20 * log10(max(rms, 1e-10))  // dB scale
    }

    // MARK: - Pitch Estimation (Autocorrelation)

    private func estimatePitch(frame: [Float]) -> Float? {
        let n = frame.count
        let minLag = Int(Float(config.sampleRate) / config.maxPitchHz)
        let maxLag = min(n - 1, Int(Float(config.sampleRate) / config.minPitchHz))

        guard minLag < maxLag, maxLag < n else { return nil }

        // Compute normalized autocorrelation
        var autocorr = [Float](repeating: 0, count: maxLag + 1)
        for lag in minLag...maxLag {
            var sum: Float = 0
            vDSP_dotpr(frame, 1, Array(frame[lag...]), 1, &sum, vDSP_Length(n - lag))
            autocorr[lag] = sum
        }

        // Normalize by zero-lag
        var zeroLag: Float = 0
        vDSP_dotpr(frame, 1, frame, 1, &zeroLag, vDSP_Length(n))
        guard zeroLag > 1e-10 else { return nil }

        // Find peak
        var bestLag = minLag
        var bestVal: Float = -Float.infinity
        for lag in minLag...maxLag {
            let normalized = autocorr[lag] / zeroLag
            if normalized > bestVal {
                bestVal = normalized
                bestLag = lag
            }
        }

        // Require minimum correlation for voiced detection
        guard bestVal / zeroLag > 0.2 else { return nil }

        return Float(config.sampleRate) / Float(bestLag)
    }

    // MARK: - Mel Filterbank Construction

    private static func buildMelFilterbank(
        nMelBands: Int,
        fftSize: Int,
        sampleRate: Int,
        fMin: Float,
        fMax: Float
    ) -> [[Float]] {
        let halfFFT = fftSize / 2

        func hzToMel(_ hz: Float) -> Float {
            2595.0 * log10(1.0 + hz / 700.0)
        }

        func melToHz(_ mel: Float) -> Float {
            700.0 * (pow(10.0, mel / 2595.0) - 1.0)
        }

        let melMin = hzToMel(fMin)
        let melMax = hzToMel(fMax)

        // nMelBands + 2 points for triangular filters
        var melPoints = [Float](repeating: 0, count: nMelBands + 2)
        for i in 0..<(nMelBands + 2) {
            melPoints[i] = melMin + Float(i) * (melMax - melMin) / Float(nMelBands + 1)
        }

        let fftBins = melPoints.map { mel -> Int in
            let hz = melToHz(mel)
            return Int((hz * Float(fftSize) / Float(sampleRate)).rounded())
        }

        var filterbank = [[Float]](repeating: [Float](repeating: 0, count: halfFFT), count: nMelBands)

        for m in 0..<nMelBands {
            let left = fftBins[m]
            let center = fftBins[m + 1]
            let right = fftBins[m + 2]

            for k in left..<center where k < halfFFT {
                let denom = Float(center - left)
                filterbank[m][k] = denom > 0 ? Float(k - left) / denom : 0
            }
            for k in center..<right where k < halfFFT {
                let denom = Float(right - center)
                filterbank[m][k] = denom > 0 ? Float(right - k) / denom : 0
            }
        }

        return filterbank
    }
}
