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
    @Published var signalLevel: Float = 0   // 0-1, for VU meter

    private var audioEngine: AVAudioEngine?
    private let bufferSize: AVAudioFrameCount = 4096
    private var smoothedFreq: Double = 0

    // MARK: - Public API

    func startListening() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.setupAudioEngine() }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.setupAudioEngine() }
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

        // RMS (signal level)
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameCount))

        DispatchQueue.main.async { self.signalLevel = min(1, rms * 10) }

        guard rms > 0.015 else {
            DispatchQueue.main.async {
                self.detectedNote = "--"
                self.frequency = 0
                self.cents = 0
            }
            return
        }

        let freq = detectPitch(buffer: channelData,
                               frameCount: frameCount,
                               sampleRate: sampleRate)

        guard freq > 60 && freq < 1400 else { return }

        // Exponential smoothing
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

    // MARK: - YIN Pitch Detection (simplified)
    // Reference: de Cheveigné & Kawahara, 2002

    private func detectPitch(buffer: UnsafeMutablePointer<Float>,
                             frameCount: Int,
                             sampleRate: Double) -> Double {
        let tauMin = max(1, Int(sampleRate / 1400))
        let tauMax = min(frameCount / 2 - 1, Int(sampleRate / 60))

        var minDiff: Float = .infinity
        var bestTau = tauMin

        // Compute difference function
        for tau in tauMin...tauMax {
            var diff: Float = 0
            let count = vDSP_Length(frameCount / 2)
            // d(tau) = sum of (x[j] - x[j+tau])^2
            var temp = [Float](repeating: 0, count: frameCount / 2)
            vDSP_vsub(buffer, 1,
                      buffer.advanced(by: tau), 1,
                      &temp, 1,
                      count)
            vDSP_dotpr(temp, 1, temp, 1, &diff, count)
            if diff < minDiff {
                minDiff = diff
                bestTau = tau
            }
        }

        guard bestTau > 0 else { return 0 }
        return sampleRate / Double(bestTau)
    }
}
