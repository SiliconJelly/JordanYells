import Foundation
import AVFoundation

class VoiceService: NSObject, ObservableObject {
    static let shared = VoiceService()
    private let synthesizer = AVSpeechSynthesizer()
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, voice: VoiceStyle = .jordan) {
        guard !text.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice.avVoice
        utterance.rate = voice.rate
        utterance.pitchMultiplier = voice.pitch
        utterance.volume = voice.volume
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
}

enum VoiceStyle {
    case jordan
    case coach
    case commentator
    
    var avVoice: AVSpeechSynthesisVoice? {
        switch self {
        case .jordan:
            return AVSpeechSynthesisVoice(language: "en-US")
        case .coach:
            return AVSpeechSynthesisVoice(language: "en-US")
        case .commentator:
            return AVSpeechSynthesisVoice(language: "en-US")
        }
    }
    
    var rate: Float {
        switch self {
        case .jordan: return 0.5
        case .coach: return 0.45
        case .commentator: return 0.55
        }
    }
    
    var pitch: Float {
        switch self {
        case .jordan: return 0.8
        case .coach: return 0.9
        case .commentator: return 1.1
        }
    }
    
    var volume: Float {
        switch self {
        case .jordan: return 0.8
        case .coach: return 0.7
        case .commentator: return 0.9
        }
    }
}

extension VoiceService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // Voice started speaking
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Voice finished speaking
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // Voice was cancelled
    }
} 