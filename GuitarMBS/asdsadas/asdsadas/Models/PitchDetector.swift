import Foundation
import AVFoundation
import Accelerate

/// Shared YIN pitch detection service.
/// Used by TunerViewModel and ScalePracticeViewModel.
final class PitchDetector {

    static let shared = PitchDetector()
    private init() {}

    // MARK: - YIN Pitch Detection
    // Reference: de Cheveigné & Kawahara, 2002

    func detectPitch(buffer: UnsafeMutablePointer<Float>,
                     frameCount: Int,
                     sampleRate: Double) -> Double {
        let tauMin = max(1, Int(sampleRate / 1400))
        let tauMax = min(frameCount / 2 - 1, Int(sampleRate / 60))
        guard tauMax > tauMin else { return 0 }

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

    // MARK: - RMS Signal Level

    func rmsLevel(buffer: UnsafeMutablePointer<Float>, frameCount: Int) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(buffer, 1, &rms, vDSP_Length(frameCount))
        return rms
    }
}
