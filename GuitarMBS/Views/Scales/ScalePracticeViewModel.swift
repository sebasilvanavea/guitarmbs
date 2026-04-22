import Foundation
import AVFoundation
import Accelerate
import Combine

// MARK: - Supporting Types

enum NoteValidationStatus {
    case waiting
    case correct
    case wrong
}

struct ScaleType: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let intervals: [Int]
    let colorName: String
}

/// A specific note position on the guitar fretboard.
struct FretPosition: Identifiable {
    let id = UUID()
    let string: Int   // 1 = high E, 6 = low E
    let fret: Int
    let note: String
}

// MARK: - ViewModel

class ScalePracticeViewModel: ObservableObject {

    // MARK: - Scale Catalogue

    static let scaleTypes: [ScaleType] = [
        ScaleType(name: "Pentatónica Menor",
                  description: "La más usada en rock y blues. 5 notas.",
                  intervals: [0, 3, 5, 7, 10],
                  colorName: "orange"),
        ScaleType(name: "Pentatónica Mayor",
                  description: "Sonido brillante. Ideal para country y pop.",
                  intervals: [0, 2, 4, 7, 9],
                  colorName: "yellow"),
        ScaleType(name: "Blues",
                  description: "Con la nota azul — carácter y sentimiento únicos.",
                  intervals: [0, 3, 5, 6, 7, 10],
                  colorName: "blue"),
        ScaleType(name: "Mayor",
                  description: "La escala fundamental de la teoría musical.",
                  intervals: [0, 2, 4, 5, 7, 9, 11],
                  colorName: "green"),
        ScaleType(name: "Menor Natural",
                  description: "Sonido melancólico y expresivo. Rock y clásica.",
                  intervals: [0, 2, 3, 5, 7, 8, 10],
                  colorName: "purple"),
        ScaleType(name: "Dórica",
                  description: "Menor con 6ta mayor. Jazz y funk.",
                  intervals: [0, 2, 3, 5, 7, 9, 10],
                  colorName: "cyan"),
        ScaleType(name: "Frigia",
                  description: "Flamenco y metal. Sabor mediterráneo.",
                  intervals: [0, 1, 3, 5, 7, 8, 10],
                  colorName: "red"),
    ]

    static let rootNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    // MARK: - Published State

    @Published var selectedScaleTypeIndex: Int = 0
    @Published var selectedRootIndex: Int = 9          // A
    @Published var isPracticing: Bool = false
    @Published var currentPositionIndex: Int = 0
    @Published var validationStatus: NoteValidationStatus = .waiting
    @Published var detectedNote: String = "--"
    @Published var signalLevel: Float = 0
    @Published var isComplete: Bool = false
    @Published var correctCount: Int = 0
    @Published var positionSequence: [FretPosition] = []
    @Published var isListening: Bool = false

    // MARK: - Private

    private var consecutiveMatches: Int = 0
    private let requiredMatches = 3
    private var audioEngine: AVAudioEngine?
    private let bufferSize: AVAudioFrameCount = 4096
    private var smoothedFreq: Double = 0

    // MARK: - Computed

    var currentScaleType: ScaleType { Self.scaleTypes[selectedScaleTypeIndex] }
    var rootNote: String { Self.rootNotes[selectedRootIndex] }

    var currentPosition: FretPosition? {
        guard !positionSequence.isEmpty,
              currentPositionIndex < positionSequence.count else { return nil }
        return positionSequence[currentPositionIndex]
    }

    var targetNote: String { currentPosition?.note ?? "--" }

    var progress: Double {
        guard !positionSequence.isEmpty else { return 0 }
        return Double(currentPositionIndex) / Double(positionSequence.count)
    }

    /// Unique scale note names, in interval order (for preview).
    var uniqueScaleNotes: [String] {
        let names = NoteFrequencyHelper.noteNames
        guard let rootIdx = names.firstIndex(of: rootNote) else { return [] }
        return currentScaleType.intervals.map { names[(rootIdx + $0) % 12] }
    }

    /// Fret range of the current position box (for fretboard display).
    var displayFretRange: ClosedRange<Int> {
        guard !positionSequence.isEmpty else { return 0...5 }
        let frets = positionSequence.map { $0.fret }
        let lo = max(0, (frets.min() ?? 0) - 1)
        let hi = min(12, (frets.max() ?? 5) + 1)
        return lo...hi
    }

    // MARK: - Position Sequence Generation

    /// Generates a guitar "box 1" ascending sequence for the selected scale/key.
    /// Returns (string, fret) pairs ordered from low string to high string, ascending pitch.
    func generatePositionSequence() -> [FretPosition] {
        let names = NoteFrequencyHelper.noteNames
        guard let rootIdx = names.firstIndex(of: rootNote) else { return [] }

        let scaleNoteSet = Set(currentScaleType.intervals.map { names[(rootIdx + $0) % 12] })

        // Find the best root position: try string 6 first, then string 5
        var boxStartFret = 0
        var found = false

        for f in 0...7 {   // prefer low positions so the box fits in 0-12
            if NoteFrequencyHelper.noteOnFret(string: 6, fret: f) == rootNote {
                boxStartFret = f
                found = true
                break
            }
        }

        if !found {   // root is high on string 6, find it on string 5 in a lower position
            for f in 0...7 {
                if NoteFrequencyHelper.noteOnFret(string: 5, fret: f) == rootNote {
                    boxStartFret = max(0, f - 1)
                    found = true
                    break
                }
            }
        }

        if !found { boxStartFret = 0 }

        let startFret = max(0, boxStartFret - 1)
        let endFret   = min(12, boxStartFret + 5)

        var result: [FretPosition] = []

        // String 6 (low E) → string 1 (high E): ascending pitch order
        for string in stride(from: 6, through: 1, by: -1) {
            for fret in startFret...endFret {
                let note = NoteFrequencyHelper.noteOnFret(string: string, fret: fret)
                if scaleNoteSet.contains(note) {
                    result.append(FretPosition(string: string, fret: fret, note: note))
                }
            }
        }

        return result
    }

    // MARK: - Practice Control

    func startPractice() {
        let positions = generatePositionSequence()
        positionSequence = positions
        currentPositionIndex = 0
        correctCount = 0
        isComplete = false
        validationStatus = .waiting
        consecutiveMatches = 0
        isPracticing = true
        startListening()
    }

    func stopPractice() {
        stopListening()
        isPracticing = false
        validationStatus = .waiting
        detectedNote = "--"
        signalLevel = 0
    }

    func restartPractice() {
        stopPractice()
        isComplete = false
    }

    // MARK: - Audio Engine

    private func startListening() {
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
        smoothedFreq = 0
        isListening = false
    }

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
            print("ScalePracticeViewModel – audio engine error: \(error)")
        }
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer, sampleRate: Double) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameCount))

        DispatchQueue.main.async { self.signalLevel = min(1, rms * 10) }

        guard rms > 0.015 else {
            DispatchQueue.main.async {
                self.detectedNote = "--"
                self.consecutiveMatches = 0
            }
            return
        }

        let freq = detectPitch(buffer: channelData,
                               frameCount: frameCount,
                               sampleRate: sampleRate)
        guard freq > 60 && freq < 1400 else { return }

        smoothedFreq = smoothedFreq == 0 ? freq : smoothedFreq * 0.75 + freq * 0.25

        DispatchQueue.main.async { [weak self] in
            guard let self, self.isPracticing, !self.isComplete else { return }
            if let info = NoteFrequencyHelper.detectNote(from: self.smoothedFreq) {
                self.detectedNote = info.note
                self.checkNote(info.note)
            }
        }
    }

    // MARK: - Validation

    private func checkNote(_ note: String) {
        guard case .waiting = validationStatus else { return }

        if note == targetNote {
            consecutiveMatches += 1
            if consecutiveMatches >= requiredMatches {
                consecutiveMatches = 0
                validationStatus = .correct
                correctCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                    self?.advance()
                }
            }
        } else {
            consecutiveMatches = 0
        }
    }

    private func advance() {
        if currentPositionIndex < positionSequence.count - 1 {
            currentPositionIndex += 1
            validationStatus = .waiting
        } else {
            isComplete = true
            stopListening()
        }
    }

    // MARK: - YIN Pitch Detection

    private func detectPitch(buffer: UnsafeMutablePointer<Float>,
                             frameCount: Int,
                             sampleRate: Double) -> Double {
        let tauMin = max(1, Int(sampleRate / 1400))
        let tauMax = min(frameCount / 2 - 1, Int(sampleRate / 60))

        var minDiff: Float = .infinity
        var bestTau = tauMin

        for tau in tauMin...tauMax {
            var diff: Float = 0
            let count = vDSP_Length(frameCount / 2)
            var temp = [Float](repeating: 0, count: frameCount / 2)
            vDSP_vsub(buffer, 1, buffer.advanced(by: tau), 1, &temp, 1, count)
            vDSP_dotpr(temp, 1, temp, 1, &diff, count)
            if diff < minDiff { minDiff = diff; bestTau = tau }
        }

        guard bestTau > 0 else { return 0 }
        return sampleRate / Double(bestTau)
    }
}
