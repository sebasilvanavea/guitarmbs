import Foundation
import Combine

// MARK: - Game Score (shared across the app)

class GameScore: ObservableObject {

    @Published var totalXP: Int
    @Published var streak: Int = 0
    @Published var completedLessonIDs: Set<String>

    init() {
        self.totalXP = UserDefaults.standard.integer(forKey: "guitarapp.totalXP")
        let ids = UserDefaults.standard.stringArray(forKey: "guitarapp.completedLessons") ?? []
        self.completedLessonIDs = Set(ids)
    }

    // MARK: Level

    var level: Int {
        var xpLeft = totalXP
        var lvl = 1
        while xpLeft >= xpThreshold(for: lvl) {
            xpLeft -= xpThreshold(for: lvl)
            lvl += 1
        }
        return lvl
    }

    var levelName: String {
        switch level {
        case 1: return "Principiante"
        case 2: return "Estudiante"
        case 3: return "Intermedio"
        case 4: return "Avanzado"
        case 5: return "Experto"
        default: return "Maestro"
        }
    }

    func xpThreshold(for level: Int) -> Int { level * 300 }

    var xpInCurrentLevel: Int {
        var xpLeft = totalXP
        var lvl = 1
        while xpLeft >= xpThreshold(for: lvl) {
            xpLeft -= xpThreshold(for: lvl)
            lvl += 1
        }
        return xpLeft
    }

    var xpProgress: Double {
        let threshold = xpThreshold(for: level)
        return Double(xpInCurrentLevel) / Double(threshold)
    }

    // MARK: Add XP

    func addXP(_ amount: Int) {
        let multiplier: Double
        switch streak {
        case 5...: multiplier = 2.0
        case 3...: multiplier = 1.5
        default:   multiplier = 1.0
        }
        totalXP += Int(Double(amount) * multiplier)
        UserDefaults.standard.set(totalXP, forKey: "guitarapp.totalXP")
    }

    func completeLesson(id: String, xp: Int) {
        let isNew = completedLessonIDs.insert(id).inserted
        if isNew { addXP(xp) }
        streak += 1
        let ids = Array(completedLessonIDs)
        UserDefaults.standard.set(ids, forKey: "guitarapp.completedLessons")
    }

    func incrementStreak() { streak += 1 }
    func resetStreak()     { streak = 0 }
}

// MARK: - Game Question

struct GameQuestion {
    let prompt: String
    let subtitle: String
    let correctAnswer: String
    let options: [String]
    var chord: Chord? = nil   // optional, for chord-quiz mode
}

// MARK: - Game Mode

enum GameMode: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case noteIdentifier = "Notas en el Mástil"
    case scaleChallenge = "Challenge de Escalas"
    case chordQuiz      = "Quiz de Acordes"

    var icon: String {
        switch self {
        case .noteIdentifier: return "music.note"
        case .scaleChallenge: return "arrow.right.circle.fill"
        case .chordQuiz:      return "questionmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .noteIdentifier: return "¿Sabes qué nota está en ese traste? ¡Demuéstralo!"
        case .scaleChallenge: return "¿Cuáles notas pertenecen a esta escala?"
        case .chordQuiz:      return "¿Reconoces el diagrama? Identifica el acorde."
        }
    }

    var color: String {
        switch self {
        case .noteIdentifier: return "blue"
        case .scaleChallenge: return "purple"
        case .chordQuiz:      return "green"
        }
    }
}
