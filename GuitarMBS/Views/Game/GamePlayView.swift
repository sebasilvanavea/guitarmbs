import SwiftUI
import Combine

// MARK: - Game Play Session

struct GamePlayView: View {

    let mode: GameMode
    @EnvironmentObject var gameScore: GameScore
    @Environment(\.dismiss) var dismiss

    @StateObject private var vm = GameViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Correctas: \(vm.correct)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.green)
                        Text("XP sesión: +\(vm.sessionXP)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(vm.streak)")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                Spacer()

                // ── Question area ────────────────────────────────────
                if let q = vm.currentQuestion {
                    VStack(spacing: 20) {
                        Text(q.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Prompt
                        promptView(for: q, mode: mode)

                        // Feedback overlay
                        if vm.showFeedback {
                            FeedbackBanner(correct: vm.lastAnswerCorrect ?? false,
                                          correctAnswer: q.correctAnswer)
                        }

                        // Answer buttons
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(q.options, id: \.self) { option in
                                AnswerButton(
                                    label: option,
                                    state: vm.showFeedback
                                           ? (option == q.correctAnswer ? .correct
                                              : (option == vm.selectedAnswer ? .wrong : .idle))
                                           : .idle
                                ) {
                                    guard !vm.showFeedback else { return }
                                    vm.answer(option, correct: q.correctAnswer, mode: mode)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Salir") {
                        gameScore.addXP(vm.sessionXP)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Pregunta \(vm.questionNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear { vm.next(mode: mode) }
    }

    @ViewBuilder
    private func promptView(for q: GameQuestion, mode: GameMode) -> some View {
        switch mode {

        case .noteIdentifier:
            VStack(spacing: 8) {
                Text(q.prompt)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                FretPositionView(prompt: q.prompt)
                    .frame(height: 100)
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
            }

        case .scaleChallenge:
            VStack(spacing: 8) {
                Text(q.prompt)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text("¿Cuál nota pertenece a esta escala?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

        case .chordQuiz:
            if let chord = q.chord {
                VStack(spacing: 8) {
                    ChordDiagramView(chord: chord)
                        .frame(width: 180, height: 180)
                }
            }
        }
    }
}

// MARK: - Answer Button

enum AnswerState { case idle, correct, wrong }

struct AnswerButton: View {
    let label: String
    let state: AnswerState
    let action: () -> Void

    private var bg: Color {
        switch state {
        case .idle:    return Color(.systemGray5)
        case .correct: return .green
        case .wrong:   return .red
        }
    }
    private var fg: Color {
        state == .idle ? .primary : .white
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title3.bold())
                .foregroundColor(fg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(bg)
                .cornerRadius(14)
                .animation(.easeInOut(duration: 0.2), value: state)
        }
    }
}

// MARK: - Feedback Banner

struct FeedbackBanner: View {
    let correct: Bool
    let correctAnswer: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
            Text(correct ? "¡Correcto! +10 XP" : "Respuesta: \(correctAnswer)")
                .font(.headline)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(correct ? Color.green : Color.red)
        .cornerRadius(14)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(), value: correct)
    }
}

// MARK: - Fret Position View

struct FretPositionView: View {
    let prompt: String   // e.g. "Cuerda 3, Traste 7"

    private var parsed: (string: Int, fret: Int)? {
        // expects "Cuerda X, Traste Y"
        let parts = prompt.components(separatedBy: ", ")
        guard parts.count == 2 else { return nil }
        let s = parts[0].filter(\.isNumber).compactMap { Int(String($0)) }.reduce(0) { $0 * 10 + $1 }
        let f = parts[1].filter(\.isNumber).compactMap { Int(String($0)) }.reduce(0) { $0 * 10 + $1 }
        return (s, f)
    }

    var body: some View {
        GeometryReader { geo in
            if let pos = parsed {
                Canvas { ctx, size in
                    let nS = 6, nF = 12
                    let hPad: CGFloat = 16
                    let vPad: CGFloat = 8
                    let gridW = size.width  - hPad * 2
                    let gridH = size.height - vPad * 2
                    let fSp = gridW / CGFloat(nF)
                    let sSp = gridH / CGFloat(nS - 1)

                    // Strings (horizontal)
                    for s in 0..<nS {
                        let y = vPad + CGFloat(s) * sSp
                        let isTarget = (s + 1) == pos.string
                        ctx.stroke(Path { p in
                            p.move(to: CGPoint(x: hPad, y: y))
                            p.addLine(to: CGPoint(x: hPad + gridW, y: y))
                        }, with: .color(.primary.opacity(isTarget ? 0.9 : 0.35)),
                                   lineWidth: isTarget ? 2 : 1)
                    }

                    // Frets (vertical)
                    for f in 0...nF {
                        let x = hPad + CGFloat(f) * fSp
                        ctx.stroke(Path { p in
                            p.move(to: CGPoint(x: x, y: vPad))
                            p.addLine(to: CGPoint(x: x, y: vPad + gridH))
                        }, with: .color(.primary.opacity(f == 0 ? 0.8 : 0.2)),
                                   lineWidth: f == 0 ? 3 : 1)
                    }

                    // Position dot
                    let dotX = hPad + CGFloat(pos.fret) * fSp - fSp / 2
                    let dotY = vPad + CGFloat(pos.string - 1) * sSp
                    if pos.fret == 0 {
                        ctx.stroke(Path { p in
                            p.addEllipse(in: CGRect(x: hPad - 14, y: dotY - 8, width: 16, height: 16))
                        }, with: .color(.orange), lineWidth: 2)
                    } else {
                        ctx.fill(Path { p in
                            p.addEllipse(in: CGRect(x: dotX - 11, y: dotY - 11, width: 22, height: 22))
                        }, with: .color(.orange))
                    }

                    // Fret dot markers (5, 7, 9, 12)
                    for marker in [5, 7, 9, 12] {
                        let x = hPad + CGFloat(marker) * fSp - fSp / 2
                        let y = vPad + gridH + 5
                        ctx.fill(Path { p in
                            p.addEllipse(in: CGRect(x: x - 3, y: y, width: 6, height: 6))
                        }, with: .color(.primary.opacity(0.25)))
                    }
                }
            }
        }
    }
}

// MARK: - Game ViewModel

class GameViewModel: ObservableObject {

    @Published var currentQuestion: GameQuestion?
    @Published var questionNumber  = 0
    @Published var correct         = 0
    @Published var streak          = 0
    @Published var sessionXP       = 0
    @Published var showFeedback    = false
    @Published var lastAnswerCorrect: Bool?
    @Published var selectedAnswer: String?

    func next(mode: GameMode) {
        currentQuestion = makeQuestion(for: mode)
        questionNumber += 1
        showFeedback    = false
        selectedAnswer  = nil
        lastAnswerCorrect = nil
    }

    func answer(_ choice: String, correct correctAnswer: String, mode: GameMode) {
        selectedAnswer = choice
        let ok = choice == correctAnswer
        lastAnswerCorrect = ok
        showFeedback = true

        if ok {
            correct += 1
            streak  += 1
            let xp = 10 + (streak >= 5 ? 10 : streak >= 3 ? 5 : 0)
            sessionXP += xp
        } else {
            streak = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            guard let self else { return }
            self.next(mode: mode)
        }
    }

    // MARK: Question Generators

    private func makeQuestion(for mode: GameMode) -> GameQuestion {
        switch mode {
        case .noteIdentifier: return noteQuestion()
        case .scaleChallenge: return scaleQuestion()
        case .chordQuiz:      return chordQuestion()
        }
    }

    private func noteQuestion() -> GameQuestion {
        let string = Int.random(in: 1...6)
        let fret   = Int.random(in: 0...12)
        let correct = NoteFrequencyHelper.noteOnFret(string: string, fret: fret)

        let distractors = NoteFrequencyHelper.noteNames
            .filter { $0 != correct }
            .shuffled()
            .prefix(3)

        let options = ([correct] + distractors).shuffled()

        return GameQuestion(
            prompt: "Cuerda \(string), Traste \(fret)",
            subtitle: "¿Cuál nota está aquí?",
            correctAnswer: correct,
            options: Array(options)
        )
    }

    private func scaleQuestion() -> GameQuestion {
        let scale = NoteFrequencyHelper.commonScales.randomElement()!
        let correctNote = scale.notes.randomElement()!

        let distractors = NoteFrequencyHelper.noteNames
            .filter { !scale.notes.contains($0) }
            .shuffled()
            .prefix(3)

        let options = ([correctNote] + distractors).shuffled()

        return GameQuestion(
            prompt: scale.name,
            subtitle: "¿Qué nota pertenece a esta escala?",
            correctAnswer: correctNote,
            options: Array(options)
        )
    }

    private func chordQuestion() -> GameQuestion {
        let chord = Chord.all.randomElement()!
        let distractors = Chord.all
            .filter { $0.name != chord.name }
            .shuffled()
            .prefix(3)
            .map { $0.name }

        let options = ([chord.name] + distractors).shuffled()

        return GameQuestion(
            prompt: chord.name,
            subtitle: "¿Cómo se llama este acorde?",
            correctAnswer: chord.name,
            options: options,
            chord: chord
        )
    }
}
