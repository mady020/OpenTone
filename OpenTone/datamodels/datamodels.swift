import Foundation

// import AVFoundation
// import Speech

// // MARK: - Terminal Colors
// extension String {
//     var red: String { "\u{001B}[0;31m\(self)\u{001B}[0m" }
//     var yellow: String { "\u{001B}[0;33m\(self)\u{001B}[0m" }
//     var blue: String { "\u{001B}[0;34m\(self)\u{001B}[0m" }
//     var bold: String { "\u{001B}[1m\(self)\u{001B}[0m" }
// }

// // MARK: - Recorder (WAV, 16-bit PCM)
// final class MicRecorder {
//     private var recorder: AVAudioRecorder?

//     func start(to url: URL) throws {
//         let settings: [String: Any] = [
//             AVFormatIDKey: kAudioFormatLinearPCM,
//             AVSampleRateKey: 44100.0,
//             AVNumberOfChannelsKey: 1,
//             AVLinearPCMBitDepthKey: 16,
//             AVLinearPCMIsFloatKey: false,
//             AVLinearPCMIsBigEndianKey: false
//         ]

//         recorder = try AVAudioRecorder(url: url, settings: settings)
//         recorder?.prepareToRecord()
//         recorder?.record()

//         print("🎤 Recording started...")
//     }

//     func stop() {
//         recorder?.stop()
//         print("🛑 Recording stopped.")
//     }
// }

// // MARK: - Speech Recognizer
// struct STTResult {
//     let text: String
//     let segments: [SFTranscriptionSegment]
// }

// final class SpeechToText {
//     func transcribe(url: URL, completion: @escaping (STTResult?) -> Void) {
//         SFSpeechRecognizer.requestAuthorization { status in
//             guard status == .authorized else { completion(nil); return }

//             let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
//             let request = SFSpeechURLRecognitionRequest(url: url)
//             request.shouldReportPartialResults = false

//             recognizer.recognitionTask(with: request) { result, error in
//                 if let error = error {
//                     print("Recognition error: \(error.localizedDescription)")
//                     completion(nil)
//                     return
//                 }

//                 if let result = result, result.isFinal {
//                     completion(STTResult(
//                         text: result.bestTranscription.formattedString,
//                         segments: result.bestTranscription.segments
//                     ))
//                 }
//             }
//         }
//     }
// }

// // MARK: - Analyzer (highlight transcript)
// final class SpeechAnalyzer {
//     let fillers: Set<String> = ["um", "uh", "erm", "hmm", "like", "basically", "actually"]
//     let pauseThreshold = 0.7
//     let lowConfidenceThreshold: Float = 0.20

//     struct Feedback {
//         var highlighted = ""
//         var totalWords = 0
//         var fillerCount = 0
//         var pauseCount = 0
//         var mispronounceCount = 0
//         var wpm = 0
//     }

//     func analyze(_ result: STTResult, duration: Double) -> Feedback {
//         var fb = Feedback()

//         for i in 0..<result.segments.count {
//             let seg = result.segments[i]
//             let word = seg.substring.lowercased()
//             fb.totalWords += 1

//             // Add space before word (except for first word)
//             if i > 0 {
//                 fb.highlighted += " "
//             }

//             // ---- Filler ----
//             if fillers.contains(word) {
//                 fb.fillerCount += 1
//                 fb.highlighted += "[\(seg.substring)]".red
//             }
//             // ---- Mispronunciation ----
//             else if seg.confidence < lowConfidenceThreshold {
//                 fb.mispronounceCount += 1
//                 fb.highlighted += "<\(seg.substring)>".yellow
//             }
//             // ---- Normal word ----
//             else {
//                 fb.highlighted += seg.substring
//             }

//             // ---- Pause Detection ----
//             if i < result.segments.count - 1 {
//                 let currentEnd = seg.timestamp + seg.duration
//                 let nextStart = result.segments[i+1].timestamp
//                 let gap = nextStart - currentEnd

//                 if gap >= pauseThreshold {
//                     fb.pauseCount += 1
//                     fb.highlighted += " " + "⏸(\(String(format: "%.1f", gap))s)".blue
//                 }
//             }
//         }

//         fb.wpm = Int(Double(fb.totalWords) / duration * 60.0)
//         return fb
//     }
// }

// @main
// struct datamodels {
//     static func main() {
//         let recorder = MicRecorder()
//         let stt = SpeechToText()
//         let analyzer = SpeechAnalyzer()

//         let fileURL = FileManager.default.homeDirectoryForCurrentUser
//             .appendingPathComponent("Desktop/mic.wav")

//         print("\n🎤 Press ENTER to start recording")
//         _ = readLine()
//         try? recorder.start(to: fileURL)

//         print("⚫ Recording... speak now. Press ENTER to stop.")
//         _ = readLine()
//         recorder.stop()

//         let duration = CMTimeGetSeconds(AVURLAsset(url: fileURL).duration)

//         print("⏳ Transcribing...")
//         stt.transcribe(url: fileURL) { result in
//             guard let result = result else { exit(1) }

//             let feedback = analyzer.analyze(result, duration: duration)

//             print("\n==================== TRANSCRIPT ====================\n")
//             print(feedback.highlighted)
//             print("\n====================================================\n")

//             print("🟢 Total words: \(feedback.totalWords)")
//             print("🟡 Words per minute: \(feedback.wpm)")
//             print("🔴 Fillers used: \(feedback.fillerCount)")
//             print("🔵 Long pauses detected: \(feedback.pauseCount)")
//             print("🟠 Possible mispronunciations: \(feedback.mispronounceCount)")
//             print("\n✅ Analysis complete.\n")

//             exit(0)
//         }

//         RunLoop.main.run()
//     }
// }
