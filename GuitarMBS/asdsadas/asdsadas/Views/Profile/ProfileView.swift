import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var gameScore: GameScore
    @EnvironmentObject var achievements: AchievementManager
    @EnvironmentObject var practiceHistory: PracticeHistory

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Player Card ──────────────────────────────────
                    playerCard

                    // ── Practice Stats ───────────────────────────────
                    practiceStatsCard

                    // ── Weekly Chart ─────────────────────────────────
                    weeklyChartCard

                    // ── Achievements ─────────────────────────────────
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("Perfil")
            .background(LinearGradient.appBackground.ignoresSafeArea())
        }
    }

    // MARK: - Player Card

    private var playerCard: some View {
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
    }

    // MARK: - Practice Stats

    private var practiceStatsCard: some View {
        HStack(spacing: 0) {
            statItem(value: "\(practiceHistory.todayMinutes)", label: "Hoy (min)", icon: "clock.fill", color: .blue)
            Divider().frame(height: 40)
            statItem(value: "\(practiceHistory.weekMinutes)", label: "Semana (min)", icon: "calendar", color: .green)
            Divider().frame(height: 40)
            statItem(value: "\(practiceHistory.streakDays)", label: "Racha (días)", icon: "flame.fill", color: .orange)
            Divider().frame(height: 40)
            statItem(value: "\(gameScore.completedLessonIDs.count)/\(Lesson.all.count)", label: "Lecciones", icon: "book.fill", color: .purple)
        }
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weekly Chart

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Última semana", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(.orange)

            let data = practiceHistory.weeklyChart
            let maxVal = max(data.max() ?? 1, 1)
            let hasData = data.contains(where: { $0 > 0 })

            if hasData {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i == 6 ? Color.orange : Color.orange.opacity(0.4))
                                .frame(height: CGFloat(data[i]) / CGFloat(maxVal) * 80 + 4)

                            Text(dayLabel(daysAgo: 6 - i))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 110)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "guitars.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.4))
                    Text("Aún no tienes sesiones esta semana")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("¡Empieza a practicar y verás tu progreso aquí!")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func dayLabel(daysAgo: Int) -> String {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(2).capitalized
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Logros", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
                Text("\(achievements.unlockedIDs.count)/\(Achievement.all.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: geo.size.width * CGFloat(achievements.progress))
                }
            }
            .frame(height: 6)

            // Unlocked
            if !achievements.unlockedAchievements.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(achievements.unlockedAchievements) { a in
                        achievementBadge(a, unlocked: true)
                    }
                }
            }

            // Locked
            if !achievements.lockedAchievements.isEmpty {
                Text("Por desbloquear")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(achievements.lockedAchievements) { a in
                        achievementBadge(a, unlocked: false)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func achievementBadge(_ achievement: Achievement, unlocked: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: achievement.icon)
                .font(.title3)
                .foregroundColor(unlocked ? .orange : .gray)
                .frame(width: 36, height: 36)
                .background(unlocked ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(achievement.title)
                    .font(.caption.bold())
                    .foregroundColor(unlocked ? .primary : .secondary)
                Text(achievement.description)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(Color(white: unlocked ? 0.12 : 0.06))
        .cornerRadius(12)
        .opacity(unlocked ? 1 : 0.6)
    }
}
