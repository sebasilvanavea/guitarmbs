import SwiftUI

struct MetronomeView: View {

    @StateObject private var engine = MetronomeEngine()
    @EnvironmentObject var practiceHistory: PracticeHistory
    @EnvironmentObject var achievements: AchievementManager
    @State private var sessionStart: Date?

    private let timeSignatures: [(beats: Int, noteValue: Int)] = [
        (2, 4), (3, 4), (4, 4), (6, 8)
    ]
    @State private var selectedSig = 2   // index into timeSignatures → 4/4

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.appBackground.ignoresSafeArea()

                VStack(spacing: 30) {

                    // ── Beat indicators ──────────────────────────────
                    HStack(spacing: 14) {
                        ForEach(1...engine.beatsPerMeasure, id: \.self) { beat in
                            let isActive = engine.currentBeat == beat && engine.isPlaying
                            Circle()
                                .fill(isActive
                                      ? (beat == 1 ? Color.orange : Color.blue)
                                      : Color.gray.opacity(0.25))
                                .frame(width: 18, height: 18)
                                .shadow(color: isActive
                                        ? (beat == 1 ? Color.orange : Color.blue).opacity(0.6)
                                        : .clear,
                                        radius: 6)
                                .animation(.easeOut(duration: 0.08), value: engine.currentBeat)
                        }
                    }
                    .padding(.top, 4)

                    // ── BPM display ──────────────────────────────────
                    VStack(spacing: 4) {
                        Text("\(Int(engine.bpm))")
                            .font(.system(size: 88, weight: .black, design: .rounded))
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.easeInOut(duration: 0.1), value: Int(engine.bpm))
                            .accessibilityLabel("\(Int(engine.bpm)) pulsaciones por minuto")

                        Text("BPM  •  \(tempoName(engine.bpm))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // ── BPM slider ───────────────────────────────────
                    VStack(spacing: 6) {
                        Slider(value: $engine.bpm, in: 40...240, step: 1)
                            .tint(.orange)
                        HStack {
                            Text("40")
                            Spacer()
                            Text("Largo       Andante       Allegro       Presto")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("240")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 28)

                    // ── Fine-tune buttons ────────────────────────────
                    HStack(spacing: 12) {
                        ForEach([-10, -1, 1, 10], id: \.self) { delta in
                            Button {
                                engine.bpm = max(40, min(240, engine.bpm + Double(delta)))
                            } label: {
                                Text(delta > 0 ? "+\(delta)" : "\(delta)")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 58, height: 42)
                                    .background(Color.orange.opacity(delta < 0 ? 0.6 : 0.85))
                                    .cornerRadius(12)
                            }
                        }
                    }

                    // ── Time signature ───────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compás")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        HStack(spacing: 10) {
                            ForEach(timeSignatures.indices, id: \.self) { i in
                                let sig = timeSignatures[i]
                                Button {
                                    selectedSig = i
                                    engine.beatsPerMeasure = sig.beats
                                } label: {
                                    VStack(spacing: 0) {
                                        Text("\(sig.beats)")
                                        Rectangle()
                                            .frame(height: 1.5)
                                        Text("\(sig.noteValue)")
                                    }
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(selectedSig == i ? .white : .primary)
                                    .frame(width: 56, height: 46)
                                    .background(selectedSig == i
                                                ? Color.orange
                                                : Color(.systemGray5))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)

                    Spacer()

                    // ── Play / Stop ──────────────────────────────────
                    Button {
                        if engine.isPlaying {
                            engine.toggle()
                            if let start = sessionStart {
                                let secs = Int(Date().timeIntervalSince(start))
                                if secs >= 10 {
                                    practiceHistory.addSession(type: .metronome, duration: secs,
                                                               details: "\(Int(engine.bpm)) BPM")
                                    if secs >= 300 { achievements.unlock("metronome-master") }
                                }
                                sessionStart = nil
                            }
                        } else {
                            sessionStart = Date()
                            engine.toggle()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(engine.isPlaying ? Color.red : Color.orange)
                                .frame(width: 90, height: 90)
                                .shadow(color: engine.isPlaying
                                        ? Color.red.opacity(0.4)
                                        : Color.orange.opacity(0.5),
                                        radius: 16, y: 6)
                            Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: engine.isPlaying ? 0 : 3)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Metrónomo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onDisappear {
                if engine.isPlaying {
                    engine.toggle()
                    if let start = sessionStart {
                        let secs = Int(Date().timeIntervalSince(start))
                        if secs >= 10 {
                            practiceHistory.addSession(type: .metronome, duration: secs,
                                                       details: "\(Int(engine.bpm)) BPM")
                            if secs >= 300 { achievements.unlock("metronome-master") }
                        }
                        sessionStart = nil
                    }
                }
            }
        }
    }

    private func tempoName(_ bpm: Double) -> String {
        switch bpm {
        case ..<60:  return "Largo"
        case ..<66:  return "Larghetto"
        case ..<76:  return "Adagio"
        case ..<108: return "Andante"
        case ..<120: return "Moderato"
        case ..<156: return "Allegro"
        case ..<176: return "Vivace"
        case ..<200: return "Presto"
        default:     return "Prestissimo"
        }
    }
}
