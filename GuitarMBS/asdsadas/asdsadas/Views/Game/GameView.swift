import SwiftUI

// MARK: - Game Hub

struct GameView: View {

    @EnvironmentObject var gameScore: GameScore
    @EnvironmentObject var practiceHistory: PracticeHistory
    @EnvironmentObject var achievements: AchievementManager
    @State private var activeMode: GameMode?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // ── Player card ──────────────────────────────────
                    PlayerCardView()

                    // ── Mode cards ───────────────────────────────────
                    Text("Elige tu desafío")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 14) {
                        ForEach(GameMode.allCases) { mode in
                            GameModeButton(mode: mode) { activeMode = mode }
                        }
                    }
                    .padding(.horizontal)

                    // ── Streak info ──────────────────────────────────
                    if gameScore.streak > 0 {
                        HStack(spacing: 8) {
                            Text("🔥")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("¡Racha de \(gameScore.streak) lecciones!")
                                    .font(.headline)
                                Text("El XP ganado se multiplica hasta x2")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Juego")
            .fullScreenCover(item: $activeMode) { mode in
                GamePlayView(mode: mode)
                    .environmentObject(gameScore)
                    .environmentObject(practiceHistory)
                    .environmentObject(achievements)
            }
        }
    }
}

// MARK: - Player Card

struct PlayerCardView: View {
    @EnvironmentObject var gameScore: GameScore

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(gameScore.levelName.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(.orange)
                    Text("Nivel \(gameScore.level)")
                        .font(.largeTitle.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(gameScore.totalXP)")
                        .font(.title.bold())
                        .foregroundColor(.orange)
                    Text("XP Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // XP progress bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.15))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                            .frame(width: geo.size.width * CGFloat(gameScore.xpProgress))
                            .animation(.spring(), value: gameScore.xpProgress)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("\(gameScore.xpInCurrentLevel) / \(gameScore.xpThreshold(for: gameScore.level)) XP")
                    Spacer()
                    Text("→ Nivel \(gameScore.level + 1)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        .padding(.horizontal)
    }
}

// MARK: - Mode Button

struct GameModeButton: View {
    let mode: GameMode
    let action: () -> Void

    private var bgColor: Color {
        switch mode {
        case .noteIdentifier: return .blue
        case .scaleChallenge: return .purple
        case .chordQuiz:      return .green
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(bgColor)
                    .cornerRadius(14)

                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
    }
}
