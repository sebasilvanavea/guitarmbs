import SwiftUI

struct TunerView: View {

    @StateObject private var vm = TunerViewModel()

    // Clamp cents to ±50 for display
    private var clampedCents: Double { max(-50, min(50, vm.cents)) }

    private var tuningColor: Color {
        let abs = Swift.abs(vm.cents)
        if abs < 5  { return .green }
        if abs < 15 { return .yellow }
        return .red
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 28) {

                    // ── Guitar string reference ──────────────────────
                    HStack(spacing: 10) {
                        ForEach(NoteFrequencyHelper.guitarStrings, id: \.string) { s in
                            VStack(spacing: 3) {
                                Text(s.note)
                                    .font(.system(.headline, design: .rounded).bold())
                                    .foregroundColor(vm.detectedNote == s.note && vm.isListening
                                                     ? .orange : .gray)
                                Text("S\(s.string)")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                            .frame(width: 44, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(vm.detectedNote == s.note && vm.isListening
                                          ? Color.orange.opacity(0.18)
                                          : Color.white.opacity(0.05))
                            )
                            .animation(.easeInOut(duration: 0.2), value: vm.detectedNote)
                        }
                    }
                    .padding(.top, 8)

                    // ── Main note display ────────────────────────────
                    VStack(spacing: 6) {
                        Text(vm.isListening && vm.frequency > 0 ? vm.detectedNote : "--")
                            .font(.system(size: 110, weight: .black, design: .rounded))
                            .foregroundColor(vm.isListening && vm.frequency > 0 ? tuningColor : .white.opacity(0.3))
                            .animation(.easeInOut(duration: 0.15), value: vm.detectedNote)
                            .contentTransition(.numericText())

                        if vm.isListening && vm.frequency > 0 {
                            Text(String(format: "%.1f Hz", vm.frequency))
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            Text("Pulsa el micrófono para afinar")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }

                    // ── Tuning meter ─────────────────────────────────
                    TuningMeter(cents: clampedCents, isActive: vm.isListening && vm.frequency > 0)
                        .frame(height: 64)
                        .padding(.horizontal, 24)

                    // Cents label
                    if vm.isListening && vm.frequency > 0 {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(tuningColor)
                                .frame(width: 8, height: 8)
                            Text(Swift.abs(vm.cents) < 3 ? "Afinado ✓"
                                 : String(format: "%+.0f¢", vm.cents))
                                .font(.headline)
                                .foregroundColor(tuningColor)
                        }
                        .animation(.easeInOut, value: vm.cents)
                    }

                    // ── Signal level bar ─────────────────────────────
                    VStack(spacing: 6) {
                        Text("Señal")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.3))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green.opacity(0.7))
                                    .frame(width: geo.size.width * CGFloat(vm.signalLevel))
                                    .animation(.easeOut(duration: 0.1), value: vm.signalLevel)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 40)

                    Spacer()

                    // ── Start / Stop button ──────────────────────────
                    Button {
                        if vm.isListening { vm.stopListening() } else { vm.startListening() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: vm.isListening ? "mic.slash.fill" : "mic.fill")
                            Text(vm.isListening ? "Detener" : "Afinar Guitarra")
                        }
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(vm.isListening
                                    ? Color.red.opacity(0.8)
                                    : Color.orange)
                        .cornerRadius(18)
                        .shadow(color: vm.isListening
                                ? Color.red.opacity(0.4)
                                : Color.orange.opacity(0.4),
                                radius: 12, y: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
                .padding(.top)
            }
            .navigationTitle("Afinador")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
    }
}

// MARK: - Tuning Meter

struct TuningMeter: View {
    let cents: Double
    let isActive: Bool

    private var indicatorColor: Color {
        let abs = Swift.abs(cents)
        if abs < 5  { return .green }
        if abs < 15 { return .yellow }
        return .red
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let centerX = w / 2
            let offset = CGFloat(cents / 50) * (w / 2 - 16)

            ZStack {
                // Track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.07))

                // Color zones
                HStack(spacing: 0) {
                    Rectangle().fill(Color.red.opacity(0.15))
                    Rectangle().fill(Color.yellow.opacity(0.15))
                    Rectangle().fill(Color.green.opacity(0.2))
                    Rectangle().fill(Color.yellow.opacity(0.15))
                    Rectangle().fill(Color.red.opacity(0.15))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Tick marks
                ForEach([-50, -25, 0, 25, 50], id: \.self) { val in
                    let x = centerX + CGFloat(val) / 50 * (w / 2 - 16)
                    Rectangle()
                        .fill(Color.white.opacity(val == 0 ? 0.8 : 0.25))
                        .frame(width: val == 0 ? 2 : 1, height: val == 0 ? h * 0.6 : h * 0.35)
                        .offset(x: x - w / 2)
                }

                // Indicator needle
                if isActive {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(indicatorColor)
                        .frame(width: 4, height: h * 0.75)
                        .shadow(color: indicatorColor.opacity(0.8), radius: 6)
                        .offset(x: offset)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: cents)
                }

                // Labels
                HStack {
                    Text("−50¢")
                    Spacer()
                    Text("+50¢")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
                .padding(.horizontal, 6)
            }
        }
    }
}
