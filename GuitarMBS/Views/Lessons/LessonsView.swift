import SwiftUI

// MARK: - Lessons List

struct LessonsView: View {

    @EnvironmentObject var gameScore: GameScore
    @State private var selectedLesson: Lesson?
    @State private var filterCategory: LessonCategory?

    private var filtered: [Lesson] {
        guard let cat = filterCategory else { return Lesson.all }
        return Lesson.all.filter { $0.category == cat }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // ── Category filter ──────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TypeChip(label: "Todas", active: filterCategory == nil) {
                            filterCategory = nil
                        }
                        ForEach(LessonCategory.allCases) { cat in
                            TypeChip(label: cat.rawValue, active: filterCategory == cat) {
                                filterCategory = filterCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                // ── Lesson list ──────────────────────────────────────
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { lesson in
                            LessonRow(lesson: lesson,
                                      completed: gameScore.completedLessonIDs.contains(lesson.id.uuidString))
                                .onTapGesture { selectedLesson = lesson }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Lecciones")
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
                    .environmentObject(gameScore)
            }
        }
    }
}

// MARK: - Lesson Row

struct LessonRow: View {
    let lesson: Lesson
    let completed: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(lesson.category.color)
                    .frame(width: 52, height: 52)
                Image(systemName: lesson.category.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(lesson.title)
                        .font(.headline)
                    Spacer()
                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                Text(lesson.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    // Difficulty
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= lesson.difficulty ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                        }
                    }
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(lesson.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(lesson.category.color)
                    Text("·")
                        .foregroundColor(.secondary)
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("+\(lesson.xpReward) XP")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .opacity(completed ? 0.75 : 1)
    }
}

// MARK: - Lesson Detail

struct LessonDetailView: View {

    let lesson: Lesson
    @EnvironmentObject var gameScore: GameScore
    @Environment(\.dismiss) var dismiss

    @State private var stepIndex = 0
    @State private var showCompletion = false

    var body: some View {
        NavigationView {
            Group {
                if showCompletion {
                    LessonCompletionView(lesson: lesson) {
                        gameScore.completeLesson(id: lesson.id.uuidString, xp: lesson.xpReward)
                        dismiss()
                    }
                } else {
                    VStack(spacing: 0) {
                        // Progress bar
                        ProgressView(value: Double(stepIndex),
                                     total: Double(lesson.steps.count))
                            .tint(lesson.category.color)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        Text("Paso \(stepIndex + 1) de \(lesson.steps.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)

                        let step = lesson.steps[stepIndex]

                        ScrollView {
                            VStack(spacing: 24) {
                                // Instruction text
                                Text(step.instruction)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                    .animation(.easeInOut, value: stepIndex)

                                // Step-specific content
                                stepContentView(step)
                                    .padding(.horizontal)
                            }
                            .padding(.bottom, 24)
                        }

                        // Next / Complete button
                        Button {
                            if stepIndex < lesson.steps.count - 1 {
                                withAnimation { stepIndex += 1 }
                            } else {
                                withAnimation { showCompletion = true }
                            }
                        } label: {
                            Text(stepIndex < lesson.steps.count - 1 ? "Siguiente →" : "¡Completar lección!")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(lesson.category.color)
                                .cornerRadius(16)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .navigationTitle(lesson.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func stepContentView(_ step: LessonStep) -> some View {
        switch step.content {

        case .chord(let name):
            if let chord = Chord.all.first(where: { $0.name == name }) {
                VStack(spacing: 8) {
                    ChordDiagramView(chord: chord)
                        .frame(width: 200, height: 200)
                    Text(chord.fullName)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }

        case .scale(let notes):
            VStack(spacing: 12) {
                Text("Notas de la escala")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(notes, id: \.self) { note in
                            Text(note)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 46, height: 46)
                                .background(lesson.category.color)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)

        case .fretboardNote(let string, let fret):
            VStack(spacing: 8) {
                Text("Cuerda \(string), Traste \(fret)")
                    .font(.headline)
                MiniFreboardView(highlightedString: string, highlightedFret: fret)
                    .frame(height: 90)
                Text("Nota: \(NoteFrequencyHelper.noteOnFret(string: string, fret: fret))")
                    .font(.title.bold())
                    .foregroundColor(lesson.category.color)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)

        case .text, .exercise:
            EmptyView()
        }
    }
}

// MARK: - Mini Fretboard

struct MiniFreboardView: View {
    let highlightedString: Int
    let highlightedFret: Int

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let strings = 6
                let frets   = 12
                let hPad: CGFloat = 20
                let vPad: CGFloat = 10
                let gridW = size.width  - hPad * 2
                let gridH = size.height - vPad * 2
                let fS = gridW / CGFloat(frets)
                let sS = gridH / CGFloat(strings - 1)

                // Strings (horizontal)
                for s in 0..<strings {
                    let y = vPad + CGFloat(s) * sS
                    ctx.stroke(Path { p in
                        p.move(to: CGPoint(x: hPad, y: y))
                        p.addLine(to: CGPoint(x: hPad + gridW, y: y))
                    }, with: .color(.primary.opacity(0.4)), lineWidth: 1)
                }

                // Frets (vertical)
                for f in 0...frets {
                    let x = hPad + CGFloat(f) * fS
                    ctx.stroke(Path { p in
                        p.move(to: CGPoint(x: x, y: vPad))
                        p.addLine(to: CGPoint(x: x, y: vPad + gridH))
                    }, with: .color(.primary.opacity(f == 0 ? 0.8 : 0.15)),
                               lineWidth: f == 0 ? 3 : 1)
                }

                // Marker dot
                let sx = hPad + CGFloat(highlightedFret) * fS - fS / 2
                let sy = vPad + CGFloat(highlightedString - 1) * sS
                if highlightedFret == 0 {
                    ctx.stroke(Path { p in
                        p.addEllipse(in: CGRect(x: hPad - 16, y: sy - 8, width: 16, height: 16))
                    }, with: .color(.orange), lineWidth: 2)
                } else {
                    ctx.fill(Path { p in
                        p.addEllipse(in: CGRect(x: sx - 9, y: sy - 9, width: 18, height: 18))
                    }, with: .color(.orange))
                }
            }
        }
    }
}

// MARK: - Completion Screen

struct LessonCompletionView: View {
    let lesson: Lesson
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 90))
                .foregroundColor(.orange)
                .shadow(color: .orange.opacity(0.4), radius: 20)

            Text("¡Lección completada!")
                .font(.largeTitle.bold())

            Text(lesson.title)
                .font(.title3)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill").foregroundColor(.orange)
                Text("+\(lesson.xpReward) XP ganados")
                    .font(.title2.bold())
                    .foregroundColor(.orange)
            }

            Spacer()

            Button(action: onContinue) {
                Text("¡Continuar!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
        }
    }
}
