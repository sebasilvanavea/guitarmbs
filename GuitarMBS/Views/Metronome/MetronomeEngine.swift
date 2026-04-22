import Foundation
import AVFoundation
import Combine

/// Accurate metronome using AVAudioEngine with synthesised click sounds.
class MetronomeEngine: ObservableObject {

    @Published var bpm: Double = 80       { didSet { if isPlaying { reschedule() } } }
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published var beatsPerMeasure: Int = 4

    private var engine      = AVAudioEngine()
    private var playerNode  = AVAudioPlayerNode()
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "metronome.queue", qos: .userInteractive)

    private var beatInterval: TimeInterval { 60.0 / bpm }

    // MARK: - Public API

    func toggle() {
        isPlaying ? stop() : start()
    }

    func restart() {
        stop()
        start()
    }

    // MARK: - Start / Stop

    private func start() {
        setupEngine()
        currentBeat = 0
        isPlaying = true
        scheduleTimer()
    }

    private func stop() {
        timer?.cancel()
        timer = nil
        engine.stop()
        engine = AVAudioEngine()   // reset for next use
        playerNode = AVAudioPlayerNode()
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentBeat = 0
        }
    }

    private func reschedule() {
        guard isPlaying else { return }
        timer?.cancel()
        timer = nil
        scheduleTimer()
    }

    // MARK: - Engine

    private func setupEngine() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("MetronomeEngine – engine start error: \(error)")
        }
    }

    // MARK: - Timer

    private func scheduleTimer() {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: beatInterval, leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in
            self?.fireBeat()
        }
        t.resume()
        timer = t
    }

    private func fireBeat() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentBeat = (self.currentBeat % self.beatsPerMeasure) + 1
        }
        let isAccent = (currentBeat % beatsPerMeasure) == 0   // first beat coming up
        playClick(accent: isAccent)
    }

    // MARK: - Click Sound (synthesised sine burst)

    private func playClick(accent: Bool) {
        let sampleRate: Double = 44_100
        let frequency: Double  = accent ? 1_000 : 750
        let duration: Double   = 0.04
        let amplitude: Float   = accent ? 0.9 : 0.65

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let data = buffer.floatChannelData?[0]
        else { return }

        buffer.frameLength = frameCount

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(exp(-t * 80))   // sharp attack, fast decay
            data[i] = amplitude * envelope * Float(sin(2 * .pi * frequency * t))
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying { playerNode.play() }
    }

    deinit { stop() }
}
