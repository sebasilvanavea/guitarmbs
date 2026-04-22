import SwiftUI

struct OnboardingView: View {

    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("guitars.fill",       "Aprende Guitarra",      "Tu compañero completo para dominar la guitarra desde cero hasta nivel avanzado.",        .orange),
        ("tuningfork",         "Afina tu Guitarra",     "Afinador profesional con detección en tiempo real. Soporta afinaciones estándar y alternativas.", .green),
        ("waveform.path",      "Practica Escalas",      "Modo Guitar Hero con validación por micrófono. 10 tipos de escala en todas las tonalidades.", .purple),
        ("gamecontroller.fill","Aprende Jugando",       "Quiz de acordes, notas y escalas. Gana XP, sube de nivel y desbloquea logros.",         .blue),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        VStack(spacing: 28) {
                            Spacer()

                            // Icon
                            ZStack {
                                Circle()
                                    .fill(page.color.opacity(0.15))
                                    .frame(width: 140, height: 140)
                                Image(systemName: page.icon)
                                    .font(.system(size: 56))
                                    .foregroundColor(page.color)
                            }

                            // Title
                            Text(page.title)
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)

                            // Subtitle
                            Text(page.subtitle)
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Spacer()
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.orange : Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 24)

                // Button
                Button {
                    HapticManager.impact(.medium)
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Siguiente" : "¡Empezar!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.orange)
                        .cornerRadius(18)
                        .padding(.horizontal, 32)
                }

                if currentPage < pages.count - 1 {
                    Button("Saltar") {
                        hasSeenOnboarding = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 12)
                }

                Spacer().frame(height: 30)
            }
        }
    }
}
