import SwiftUI

// MARK: - iOS-only navigation helpers

extension View {
    @ViewBuilder
    func inlineNavTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

// MARK: - Root Container

struct ScalePracticeView: View {
    @StateObject private var vm = ScalePracticeViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if vm.isComplete {
                    CompletionScaleView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity))
                } else if vm.isPracticing {
                    GuitarHeroPracticeView(vm: vm)
                        .transition(.opacity)
                } else {
                    ScaleSelectionView(vm: vm)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: vm.isPracticing)
            .animation(.easeInOut(duration: 0.3), value: vm.isComplete)
            .navigationTitle("Escalas")
            .inlineNavTitle()
            .toolbar {
                if vm.isPracticing && !vm.isComplete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Salir") { vm.stopPractice() }
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - ──────────────────────────────────────
// MARK: SELECTION SCREEN
// MARK: ──────────────────────────────────────

struct ScaleSelectionView: View {
    @ObservedObject var vm: ScalePracticeViewModel
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "guitars.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Aprende Escalas")
                        .font(.title2).bold().foregroundColor(.white)
                    Text("Toca cada nota en el mástil.\nEl micrófono valida tu afinación en tiempo real.")
                        .font(.subheadline).foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Root key
                VStack(alignment: .leading, spacing: 10) {
                    Label("Tonalidad", systemImage: "tuningfork")
                        .font(.headline).foregroundColor(.orange)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(ScalePracticeViewModel.rootNotes.enumerated()), id: \.offset) { idx, note in
                                Button { vm.selectedRootIndex = idx } label: {
                                    Text(note)
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                        .frame(width: 46, height: 46)
                                        .background(vm.selectedRootIndex == idx ? Color.orange : Color.white.opacity(0.08))
                                        .foregroundColor(vm.selectedRootIndex == idx ? .black : .white)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .padding(.horizontal)

                // Scale type grid
                VStack(alignment: .leading, spacing: 10) {
                    Label("Tipo de escala", systemImage: "list.bullet.rectangle")
                        .font(.headline).foregroundColor(.orange)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(ScalePracticeViewModel.scaleTypes.enumerated()), id: \.offset) { idx, scale in
                            ScaleTypeCard(scale: scale, isSelected: vm.selectedScaleTypeIndex == idx)
                                .onTapGesture { vm.selectedScaleTypeIndex = idx }
                        }
                    }
                    .padding(.horizontal)
                }

                // Note preview
                ScalePreviewPills(notes: vm.uniqueScaleNotes,
                                  rootNote: vm.rootNote,
                                  scaleName: vm.currentScaleType.name)
                    .padding(.horizontal)

                // Start
                Button { vm.startPractice() } label: {
                    Label("Comenzar Práctica", systemImage: "mic.fill")
                        .font(.headline).foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(14)
                        .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: Scale Type Card

struct ScaleTypeCard: View {
    let scale: ScaleType
    let isSelected: Bool

    var accent: Color {
        switch scale.colorName {
        case "orange":  return .orange
        case "yellow":  return .yellow
        case "blue":    return .blue
        case "green":   return .green
        case "purple":  return .purple
        case "cyan":    return Color(red: 0, green: 0.8, blue: 0.9)
        case "red":     return .red
        default:        return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(accent).frame(width: 9, height: 9)
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(accent) }
            }
            Text(scale.name).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            Text(scale.description).font(.caption).foregroundColor(.gray).lineLimit(2)
        }
        .padding(14)
        .background(isSelected ? accent.opacity(0.18) : Color.white.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? accent : .clear, lineWidth: 1.5))
        .cornerRadius(12)
    }
}

// MARK: Note Preview Pills

struct ScalePreviewPills: View {
    let notes: [String]
    let rootNote: String
    let scaleName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(scaleName) de \(rootNote):")
                .font(.caption).foregroundColor(.gray)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(notes, id: \.self) { note in
                        Text(note)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(note == rootNote ? Color.orange.opacity(0.3) : Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - ──────────────────────────────────────
// MARK: GUITAR HERO PRACTICE SCREEN
// MARK: ──────────────────────────────────────

struct GuitarHeroPracticeView: View {
    @ObservedObject var vm: ScalePracticeViewModel

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────
            VStack(spacing: 4) {
                Text("\(vm.currentScaleType.name)  ·  \(vm.rootNote)")
                    .font(.subheadline).foregroundColor(.gray)

                GHProgressBar(current: vm.currentPositionIndex,
                              total: vm.positionSequence.count)
                    .padding(.horizontal)
            }
            .padding(.top, 10)
            .padding(.bottom, 6)

            // ── Upcoming note queue ──────────────────────────────
            GHNoteQueue(positions: vm.positionSequence,
                        currentIndex: vm.currentPositionIndex)
                .frame(height: 54)
                .padding(.horizontal)
                .padding(.bottom, 6)

            // ── Main fretboard (Guitar Hero) ─────────────────────
            GHFretboardView(positions: vm.positionSequence,
                            currentIndex: vm.currentPositionIndex,
                            validationStatus: vm.validationStatus,
                            fretRange: vm.displayFretRange)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 6)

            // ── Current note instruction ─────────────────────────
            if let pos = vm.currentPosition {
                GHInstructionPanel(position: pos, status: vm.validationStatus)
                    .padding(.horizontal)
                    .padding(.top, 6)
            }

            // ── Mic panel ───────────────────────────────────────
            GHMicPanel(vm: vm)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }
}

// MARK: Progress Bar

struct GHProgressBar: View {
    let current: Int
    let total: Int

    var progress: Double { total > 0 ? Double(current) / Double(total) : 0 }

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4).fill(Color.orange)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.4), value: current)
                }
            }
            .frame(height: 6)

            Text("\(current) / \(total) notas")
                .font(.caption2).foregroundColor(.gray)
        }
    }
}

// MARK: Note Queue

struct GHNoteQueue: View {
    let positions: [FretPosition]
    let currentIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(positions.enumerated()), id: \.offset) { idx, pos in
                    let isDone    = idx < currentIndex
                    let isCurrent = idx == currentIndex
                    let diff      = idx - currentIndex

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isDone    ? Color.green.opacity(0.25) :
                                  isCurrent ? Color.orange.opacity(0.25) :
                                              Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCurrent ? Color.orange : .clear, lineWidth: 1.5)
                            )

                        VStack(spacing: 1) {
                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                            } else {
                                Text(pos.note)
                                    .font(.system(size: isCurrent ? 16 : 13,
                                                  weight: .black, design: .monospaced))
                                    .foregroundColor(isCurrent ? .orange : .white.opacity(diff < 4 ? 0.7 : 0.3))
                                Text("S\(pos.string) F\(pos.fret)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray.opacity(isCurrent ? 1 : 0.5))
                            }
                        }
                    }
                    .frame(width: isCurrent ? 50 : 40, height: isCurrent ? 50 : 40)
                    .animation(.spring(response: 0.3), value: currentIndex)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

// MARK: Guitar Hero Fretboard

struct GHFretboardView: View {
    let positions: [FretPosition]
    let currentIndex: Int
    let validationStatus: NoteValidationStatus
    let fretRange: ClosedRange<Int>

    @State private var pulseOpacity: Double = 0.3
    @State private var pulseScale: CGFloat = 1.0
    @State private var hitFlash: Bool = false

    // Layout constants
    private let lPad: CGFloat = 34
    private let rPad: CGFloat = 10
    private let tPad: CGFloat = 18
    private let bPad: CGFloat = 26
    private let stringLabels = ["E", "B", "G", "D", "A", "E"]
    private let stringThickness: [CGFloat] = [0.8, 1.0, 1.3, 1.6, 2.0, 2.5]

    private var fretCount: Int {
        max(1, fretRange.upperBound - fretRange.lowerBound + 1)
    }

    // ── Layout helpers as proper struct methods ────────────────
    private func xFor(fret: Int, width: CGFloat) -> CGFloat {
        let usableW = width - lPad - rPad
        let fretW = usableW / CGFloat(fretCount)
        return lPad + fretW * CGFloat(fret - fretRange.lowerBound) + fretW * 0.5
    }

    private func yFor(string: Int, height: CGFloat) -> CGFloat {
        let usableH = height - tPad - bPad
        let strGap  = usableH / 5.0
        return tPad + strGap * CGFloat(string - 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                // ─── Static fretboard drawn in Canvas ─────────────
                Canvas { ctx, size in
                    drawFretboard(&ctx, size: size)
                }
                .frame(width: geo.size.width, height: geo.size.height)

                // ─── Animated note dots as SwiftUI views ──────────
                ForEach(Array(positions.enumerated()), id: \.offset) { idx, pos in
                    if fretRange.contains(pos.fret) {
                        let isCurrent = idx == currentIndex
                        NoteDot(
                            note:             pos.note,
                            isDone:           idx < currentIndex,
                            isCurrent:        isCurrent,
                            pulseScale:       isCurrent ? pulseScale : 1.0,
                            pulseOpacity:     isCurrent ? pulseOpacity : 0,
                            hitFlash:         isCurrent && hitFlash,
                            validationStatus: isCurrent ? validationStatus : .waiting
                        )
                        .position(
                            x: xFor(fret: pos.fret,     width:  geo.size.width),
                            y: yFor(string: pos.string, height: geo.size.height)
                        )
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.06))
                .shadow(color: .black.opacity(0.5), radius: 12)
        )
        .onAppear { startPulse() }
        // onChange(of:perform:) works on iOS 14+ (deprecated in 17 but safe to use)
        .onChange(of: currentIndex, perform: { _ in
            withAnimation(.easeOut(duration: 0.15)) { hitFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation { hitFlash = false }
            }
        })
        .onChange(of: validationStatus, perform: { status in
            if case .correct = status { triggerCorrectAnimation() }
        })
    }

    // ── Canvas drawing (plain function — no @ViewBuilder issues) ──
    private func drawFretboard(_ ctx: inout GraphicsContext, size: CGSize) {
        let usableW = size.width - lPad - rPad
        let usableH = size.height - tPad - bPad
        guard usableW > 0, usableH > 0 else { return }

        let fretW  = usableW / CGFloat(fretCount)
        let strGap = usableH / 5.0

        // Fret wires
        for i in 0...fretCount {
            let x = lPad + fretW * CGFloat(i)
            let isNut = (fretRange.lowerBound == 0 && i == 0)
            var p = Path()
            p.move(to: CGPoint(x: x, y: tPad))
            p.addLine(to: CGPoint(x: x, y: tPad + strGap * 5))
            ctx.stroke(p,
                       with: .color(.white.opacity(isNut ? 0.7 : 0.18)),
                       lineWidth: isNut ? 3 : 1)
        }

        // Strings
        for s in 1...6 {
            let y = tPad + strGap * CGFloat(s - 1)
            var p = Path()
            p.move(to: CGPoint(x: lPad, y: y))
            p.addLine(to: CGPoint(x: lPad + usableW, y: y))
            ctx.stroke(p,
                       with: .color(.white.opacity(0.3)),
                       lineWidth: stringThickness[s - 1])
        }

        // Fret numbers + position dot markers
        let markerFrets = Set([3, 5, 7, 9, 12])
        for fret in fretRange {
            let cellIdx = fret - fretRange.lowerBound
            let x = lPad + fretW * CGFloat(cellIdx) + fretW * 0.5
            let y = tPad + strGap * 5 + 14
            let isMarker = markerFrets.contains(fret)
            ctx.draw(
                Text("\(fret)")
                    .font(.system(size: isMarker ? 9 : 8, weight: isMarker ? .medium : .regular))
                    .foregroundColor(.white.opacity(isMarker ? 0.5 : 0.25)),
                at: CGPoint(x: x, y: y)
            )
        }

        // String labels (left side)
        for s in 1...6 {
            let y = tPad + strGap * CGFloat(s - 1)
            ctx.draw(
                Text(stringLabels[s - 1])
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45)),
                at: CGPoint(x: lPad - 16, y: y)
            )
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.15
            pulseScale   = 1.35
        }
    }

    private func triggerCorrectAnimation() {
        withAnimation(.easeOut(duration: 0.2)) { pulseScale = 1.6 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring()) { pulseScale = 1.0 }
        }
    }
}

// MARK: Note Dot

struct NoteDot: View {
    let note: String
    let isDone: Bool
    let isCurrent: Bool
    let pulseScale: CGFloat
    let pulseOpacity: Double
    let hitFlash: Bool
    let validationStatus: NoteValidationStatus

    private var ringColor: Color {
        if isDone { return .green }
        if case .correct = validationStatus { return .green }
        return .orange
    }

    var body: some View {
        ZStack {
            if isCurrent {
                // Outer pulse ring
                Circle()
                    .fill(ringColor.opacity(pulseOpacity))
                    .frame(width: 52, height: 52)
                    .scaleEffect(pulseScale)

                // Inner glow ring
                Circle()
                    .stroke(ringColor.opacity(0.6), lineWidth: 2)
                    .frame(width: 36, height: 36)

                // Main dot
                Circle()
                    .fill(ringColor)
                    .frame(width: 30, height: 30)
                    .shadow(color: ringColor.opacity(0.8), radius: 8)

                Text(note)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.black)

            } else if isDone {
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 26, height: 26)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)

            } else {
                // Upcoming
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                Text(note)
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

// MARK: Instruction Panel

struct GHInstructionPanel: View {
    let position: FretPosition
    let status: NoteValidationStatus

    private let stringNames = ["", "E alta", "B", "G", "D", "A", "E baja"]

    var borderColor: Color {
        switch status {
        case .correct: return .green
        case .wrong:   return .red
        case .waiting: return .orange.opacity(0.5)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Note badge
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.orange)
                    .frame(width: 54, height: 54)
                Text(position.note)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.black)
            }

            // Instruction
            VStack(alignment: .leading, spacing: 3) {
                Text("TOCA AHORA")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                    .tracking(1.5)

                Text("Cuerda \(position.string)  ·  Traste \(position.fret)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text(stringNames[position.string])
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Status icon
            Group {
                switch status {
                case .correct:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title).foregroundColor(.green)
                case .wrong:
                    Image(systemName: "xmark.circle.fill")
                        .font(.title).foregroundColor(.red)
                case .waiting:
                    Image(systemName: "mic.circle.fill")
                        .font(.title).foregroundColor(.orange.opacity(0.6))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: status)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color(white: 0.1))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1.5))
        .cornerRadius(14)
        .animation(.easeInOut(duration: 0.25), value: status)
    }
}

// MARK: Mic Panel

struct GHMicPanel: View {
    @ObservedObject var vm: ScalePracticeViewModel

    var statusText: String {
        switch vm.validationStatus {
        case .waiting:
            return vm.detectedNote == "--"
                ? "Escuchando… toca la nota \(vm.targetNote)"
                : "Detectado: \(vm.detectedNote)"
        case .correct: return "✓ ¡Correcto! Siguiente…"
        case .wrong:   return "Intenta de nuevo"
        }
    }

    var statusColor: Color {
        switch vm.validationStatus {
        case .waiting: return .gray
        case .correct: return .green
        case .wrong:   return .red
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: vm.isListening ? "mic.fill" : "mic.slash")
                .foregroundColor(vm.isListening ? .orange : .gray)
                .frame(width: 20)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.07))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(vm.validationStatus == .correct ? Color.green : Color.orange.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(vm.signalLevel))
                        .animation(.linear(duration: 0.05), value: vm.signalLevel)
                }
            }
            .frame(height: 7)

            HStack(spacing: 6) {
                Text(vm.detectedNote)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(vm.detectedNote == vm.targetNote ? .orange : .white)
                    .frame(width: 28)

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .lineLimit(1)
                    .animation(.easeInOut, value: vm.validationStatus)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - ──────────────────────────────────────
// MARK: COMPLETION SCREEN
// MARK: ──────────────────────────────────────

struct CompletionScaleView: View {
    @ObservedObject var vm: ScalePracticeViewModel
    @State private var starScale: CGFloat = 0.3
    @State private var showContent: Bool = false

    var accuracy: Int {
        guard vm.positionSequence.count > 0 else { return 0 }
        return Int(Double(vm.correctCount) / Double(vm.positionSequence.count) * 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Trophy animation
            VStack(spacing: 12) {
                Image(systemName: accuracy == 100 ? "star.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(accuracy == 100 ? .orange : .green)
                    .scaleEffect(starScale)

                Text(accuracy == 100 ? "¡Perfecto!" : "¡Escala completada!")
                    .font(.title.bold()).foregroundColor(.white)

                Text("\(vm.currentScaleType.name)  ·  \(vm.rootNote)")
                    .font(.subheadline).foregroundColor(.gray)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                    starScale = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { showContent = true }
                }
            }

            Spacer()

            // Stats
            if showContent {
                HStack(spacing: 24) {
                    StatBlock(value: "\(vm.correctCount)", label: "Notas\ncorrectas", color: .green)
                    StatBlock(value: "\(vm.positionSequence.count)", label: "Total de\nposiciones", color: .white)
                    StatBlock(value: "\(accuracy)%", label: "Precisión", color: .orange)
                }
                .padding(20)
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            VStack(spacing: 12) {
                Button { vm.startPractice() } label: {
                    Label("Repetir escala", systemImage: "arrow.counterclockwise")
                        .font(.headline).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.orange).cornerRadius(14)
                }

                Button { vm.restartPractice() } label: {
                    Label("Elegir otra escala", systemImage: "music.note.list")
                        .font(.subheadline).foregroundColor(.orange)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.orange.opacity(0.12)).cornerRadius(14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }
}

struct StatBlock: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2).foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Equatable conformance for onChange

extension NoteValidationStatus: Equatable {
    static func == (lhs: NoteValidationStatus, rhs: NoteValidationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.waiting, .waiting), (.correct, .correct), (.wrong, .wrong): return true
        default: return false
        }
    }
}

// MARK: - Preview

#Preview {
    ScalePracticeView()
        .environmentObject(GameScore())
}
