import Foundation
import AVFoundation
import Accelerate
import Combine

class TunerViewModel: ObservableObject {

    @Published var detectedNote: String = "--"
    @Published var detectedOctave: Int = 4
    @Published var frequency: Double = 0
    @Published var cents: Double = 0
    @Published var isListening: Bool = false
    @Published var signalLevel: Float = 0
    @Published var micPermissionDenied: Bool = false

    // Tuning configuration
    @Published var selectedTuningIndex: Int = 0

    static let tunings: [(name: String, strings: [(string: Int, note: String, octave: Int)])] = [
        ("Estándar",    [(1,"E",4), (2,"B",3), (3,"G",3), (4,"D",3), (5,"A",2), (6,"E",2)]),
        ("Drop D",      [(1,"E",4), (2,"B",3), (3,"G",3), (4,"D",3), (5,"A",2), (6,"D",2)]),
        ("Open G",      [(1,"D",4), (2,"B",3), (3,"D",3), (4,"G",3), (5,"B",2), (6,"D",2)]),
        ("DADGAD",      [(1,"D",4), (2,"A",3), (3,"G",3), (4,"D",3), (5,"A",2), (6,"D",2)]),
        ("Open D",      [(1,"D",4), (2,"A",3), (3,"F#",3),(4,"D",3), (5,"A",2), (6,"D",2)]),
        ("Half Step ↓", [(1,"D#",4),(2,"A#",3),(3,"F#",3),(4,"C#",3),(5,"G#",2),(6,"D#",2)]),
    ]

    var currentTuning: (name: String, strings: [(string: Int, note: String, octave: Int)]) {
        Self.tunings[selectedTuningIndex]
    }

    private var audioEngine: AVAudioEngine?
    private let bufferSize: AVAudioFrameCount = 4096
    private var smoothedFreq: Double = 0

    // MARK: - Public API

    func startListening() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.micPermissionDenied = false
                    self?.setupAudioEngine()
                } else {
                    self?.micPermissionDenied = true
                }
            }
        }
    }

    func stopListening() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isListening = false
        detectedNote = "--"
        frequency = 0
        cents = 0
        signalLevel = 0
        smoothedFreq = 0
    }

    // MARK: - Audio Engine Setup

    private func setupAudioEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)

            audioEngine = AVAudioEngine()
            guard let engine = audioEngine else { return }

            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0,
                                 bufferSize: bufferSize,
                                 format: format) { [weak self] buffer, _ in
                self?.processBuffer(buffer, sampleRate: format.sampleRate)
            }

            try engine.start()
            isListening = true
        } catch {
            print("TunerViewModel – audio engine error: \(error)")
        }
    }

    // MARK: - Buffer Processing

    private func processBuffer(_ buffer: AVAudioPCMBuffer, sampleRate: Double) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        let rms = PitchDetector.shared.rmsLevel(buffer: channelData, frameCount: frameCount)

        DispatchQueue.main.async { self.signalLevel = min(1, rms * 10) }

        guard rms > 0.015 else {
            DispatchQueue.main.async {
                self.detectedNote = "--"
                self.frequency = 0
                self.cents = 0
            }
            return
        }

        let freq = PitchDetector.shared.detectPitch(buffer: channelData,
                                                     frameCount: frameCount,
                                                     sampleRate: sampleRate)

        guard freq > 60 && freq < 1400 else { return }

        smoothedFreq = smoothedFreq == 0 ? freq : smoothedFreq * 0.75 + freq * 0.25

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.frequency = self.smoothedFreq
            if let info = NoteFrequencyHelper.detectNote(from: self.smoothedFreq) {
                self.detectedNote  = info.note
                self.detectedOctave = info.octave
                self.cents         = info.cents
            }
        }
    }
}
