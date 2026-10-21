import AVFoundation
import Observation
import Foundation

@MainActor @Observable
final class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, language: String, voiceIdentifier: String? = nil, speed: Double? = nil) {
        guard !text.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        let utterance = AVSpeechUtterance(string: text)
        let identifier = voiceIdentifier ?? UserDefaults.standard.string(forKey: "pronunciationVoiceIdentifier") ?? ""
        let savedVoice = AVSpeechSynthesisVoice(identifier: identifier)
        let family = language.split(separator: "-").first
        utterance.voice = savedVoice?.language.split(separator: "-").first == family ? savedVoice : AVSpeechSynthesisVoice(language: language)
        let storedSpeed = UserDefaults.standard.object(forKey: "pronunciationSpeed") as? Double ?? 1
        let multiplier = min(max(speed ?? storedSpeed, 0.5), 1.5)
        utterance.rate = Float(0.43 * multiplier)
        synthesizer.speak(utterance)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}
