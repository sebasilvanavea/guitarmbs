import Foundation
import Combine

// MARK: - Practice Session Record

struct PracticeSession: Identifiable, Codable {
    let id: String
    let date: Date
    let durationSeconds: Int
    let type: PracticeType
    let details: String

    enum PracticeType: String, Codable {
        case tuner     = "Afinador"
        case metronome = "Metrónomo"
        case scales    = "Escalas"
        case lessons   = "Lecciones"
        case game      = "Juego"
    }
}

// MARK: - Practice History Manager

class PracticeHistory: ObservableObject {

    @Published var sessions: [PracticeSession] = []

    private let storageKey = "guitarapp.practiceHistory"

    init() {
        load()
    }

    // MARK: - Public

    func addSession(type: PracticeSession.PracticeType, duration: Int, details: String = "") {
        let session = PracticeSession(
            id: UUID().uuidString,
            date: Date(),
            durationSeconds: duration,
            type: type,
            details: details
        )
        sessions.insert(session, at: 0)
        // Keep max 200 sessions
        if sessions.count > 200 { sessions = Array(sessions.prefix(200)) }
        save()
    }

    var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.durationSeconds } / 60
    }

    var weekMinutes: Int {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return sessions
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.durationSeconds } / 60
    }

    var streakDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessionDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })

        var streak = 0
        var checkDate = today
        while sessionDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    /// Minutes per day for the last 7 days (index 0 = 6 days ago, index 6 = today).
    var weeklyChart: [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: today) else { return 0 }
            return sessions
                .filter { calendar.startOfDay(for: $0.date) == date }
                .reduce(0) { $0 + $1.durationSeconds } / 60
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PracticeSession].self, from: data) else { return }
        sessions = decoded
    }
}
