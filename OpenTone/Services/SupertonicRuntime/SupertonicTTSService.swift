import Foundation
import OnnxRuntimeBindings

final class TTSService {
    enum Voice { case male, female }
    enum Language: String, CaseIterable {
        case en = "en"
        case ko = "ko"
        case es = "es"
        case pt = "pt"
        case fr = "fr"
        
        var displayName: String {
            switch self {
            case .en: return "English"
            case .ko: return "한국어"
            case .es: return "Español"
            case .pt: return "Português"
            case .fr: return "Français"
            }
        }
    }

    private let env: ORTEnv
    private let textToSpeech: TextToSpeech
    private let bundleOnnxDir: String
    private let sampleRate: Int

    init() throws {
        bundleOnnxDir = try Self.locateOnnxDirInBundle()
        env = try ORTEnv(loggingLevel: .warning)
        textToSpeech = try loadTextToSpeech(bundleOnnxDir, false, env)
        sampleRate = textToSpeech.sampleRate
    }

    func synthesize(text: String, nfe: Int, voice: Voice, language: Language, volumeBoost: Float = 1.5) async throws -> URL {
        // Load style for the selected voice, falling back if a style file is malformed.
        let style = try Self.loadVoiceStyleWithFallback(voice: voice)

        // 2) Synthesize via packed TextToSpeech component
        let (wav, duration) = try textToSpeech.call(text, language.rawValue, style, nfe)
        let predictedSamples = Int(Double(sampleRate) * Double(duration))
        let wavLenSample: Int
        if predictedSamples > 0 {
            wavLenSample = min(predictedSamples, wav.count)
        } else {
            // Some model/runtime combos can report zero/invalid duration while waveform exists.
            wavLenSample = wav.count
        }

        guard wavLenSample > 0 else {
            throw NSError(
                domain: "TTS",
                code: -103,
                userInfo: [NSLocalizedDescriptionKey: "Supertonic produced empty audio waveform."]
            )
        }

        let wavOut = Array(wav[0..<wavLenSample])
        let clampedBoost = max(0.8, min(volumeBoost, 1.5))
        let boostedWav = wavOut.map { sample in
            max(-1.0, min(1.0, sample * clampedBoost))
        }

        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("supertonic_tts_\(UUID().uuidString).wav")
        try writeWavFile(tmpURL.path, boostedWav, sampleRate)

        return tmpURL
    }

    // MARK: - Resource location helpers
    private static func locateOnnxDirInBundle() throws -> String {
        let bundle = Bundle.main
        let fm = FileManager.default

        func dirHasRequiredFiles(_ dir: URL) -> Bool {
            let required = [
                "tts.json",
                "unicode_indexer.json",
                "duration_predictor.onnx",
                "text_encoder.onnx",
                "vector_estimator.onnx",
                "vocoder.onnx"
            ]
            return required.allSatisfy { fm.fileExists(atPath: dir.appendingPathComponent($0).path) }
        }

        var candidates: [URL] = []
        if let dir = bundle.resourceURL?.appendingPathComponent("onnx", isDirectory: true) { candidates.append(dir) }
        if let dir = bundle.resourceURL?.appendingPathComponent("assets/onnx", isDirectory: true) { candidates.append(dir) }
        if let url = bundle.url(forResource: "tts", withExtension: "json", subdirectory: "onnx") { candidates.append(url.deletingLastPathComponent()) }
        if let url = bundle.url(forResource: "tts", withExtension: "json", subdirectory: "assets/onnx") { candidates.append(url.deletingLastPathComponent()) }
        if let url = bundle.url(forResource: "tts", withExtension: "json", subdirectory: nil) { candidates.append(url.deletingLastPathComponent()) }
        if let root = bundle.resourceURL { candidates.append(root) }

        for dir in candidates {
            if dirHasRequiredFiles(dir) { return dir.path }
        }
        throw NSError(
            domain: "TTS",
            code: -100,
            userInfo: [NSLocalizedDescriptionKey: "Could not find the onnx directory in the bundle. Please make sure the onnx folder (as a folder reference) is included in Copy Bundle Resources in Xcode."]
        )
    }

    private static func locateVoiceStyleURL(fileName: String) -> URL? {
        let bundle = Bundle.main
        let candidates: [URL?] = [
            bundle.url(forResource: fileName, withExtension: "json", subdirectory: "voice_styles"),
            bundle.url(forResource: fileName, withExtension: "json", subdirectory: "assets/voice_styles"),
            bundle.url(forResource: fileName, withExtension: "json", subdirectory: nil)
        ]
        for url in candidates {
            if let url = url { return url }
        }
        // Fallback: scan folders if needed
        if let folder1 = bundle.resourceURL?.appendingPathComponent("voice_styles", isDirectory: true) {
            let file = folder1.appendingPathComponent("\(fileName).json")
            if FileManager.default.fileExists(atPath: file.path) { return file }
        }
        if let folder2 = bundle.resourceURL?.appendingPathComponent("assets/voice_styles", isDirectory: true) {
            let file = folder2.appendingPathComponent("\(fileName).json")
            if FileManager.default.fileExists(atPath: file.path) { return file }
        }
        return nil
    }

    private static func loadVoiceStyleWithFallback(voice: Voice) throws -> Style {
        let preferred = (voice == .male) ? ["M1", "F1"] : ["F1", "M1"]
        var lastError: Error?

        for name in preferred {
            guard let url = locateVoiceStyleURL(fileName: name) else { continue }
            do {
                return try loadVoiceStyle([url.path], verbose: false)
            } catch {
                lastError = error
                print("TTSService: style \(name).json failed to load, trying fallback. Error: \(error.localizedDescription)")
            }
        }

        if let lastError {
            throw lastError
        }

        throw NSError(
            domain: "TTS",
            code: -102,
            userInfo: [NSLocalizedDescriptionKey: "Could not find any valid voice style JSON in the bundle (expected M1.json/F1.json)."]
        )
    }
}
