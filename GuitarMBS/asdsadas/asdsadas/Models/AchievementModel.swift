import Foundation
import Combine
import UIKit

// MARK: - Achievement

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory

    enum AchievementCategory: String {
        case practice  = "Práctica"
        case lessons   = "Lecciones"
        case game      = "Juego"
        case milestone = "Hito"
    }
}

// MARK: - Achievement Registry

extension Achievement {
    static let all: [Achievement] = [
        // Practice
        Achievement(id: "first-tune",         title: "Primera afinación",       description: "Usa el afinador por primera vez",          icon: "tuningfork",             category: .practice),
        Achievement(id: "first-scale",        title: "Primera escala",          description: "Completa una escala en modo práctica",     icon: "waveform.path",          category: .practice),
        Achievement(id: "perfect-scale",      title: "Escala perfecta",         description: "Completa una escala con 100% de precisión", icon: "star.fill",             category: .practice),
        Achievement(id: "metronome-master",   title: "Maestro del tempo",       description: "Usa el metrónomo por 5 minutos",           icon: "metronome.fill",         category: .practice),
        Achievement(id: "all-scales",         title: "Explorador de escalas",   description: "Prueba los 10 tipos de escala",            icon: "map.fill",               category: .practice),

        // Lessons
        Achievement(id: "first-lesson",       title: "Estudiante",              description: "Completa tu primera lección",              icon: "book.fill",              category: .lessons),
        Achievement(id: "five-lessons",       title: "Dedicado",                description: "Completa 5 lecciones",                     icon: "books.vertical.fill",    category: .lessons),
        Achievement(id: "all-lessons",        title: "Graduado",                description: "Completa todas las lecciones",             icon: "graduationcap.fill",     category: .lessons),

        // Game
        Achievement(id: "first-game",         title: "Jugador",                 description: "Juega tu primera partida",                 icon: "gamecontroller.fill",    category: .game),
        Achievement(id: "streak-5",           title: "En racha",                description: "Consigue una racha de 5 respuestas",       icon: "flame.fill",             category: .game),
        Achievement(id: "streak-10",          title: "Imparable",               description: "Consigue una racha de 10 respuestas",      icon: "bolt.fill",              category: .game),
        Achievement(id: "game-50-correct",    title: "Sabio musical",           description: "Responde 50 preguntas correctamente",      icon: "brain.head.profile",     category: .game),

        // Milestones
        Achievement(id: "level-3",            title: "Intermedio",              description: "Alcanza el nivel 3",                       icon: "arrow.up.circle.fill",   category: .milestone),
        Achievement(id: "level-5",            title: "Experto",                 description: "Alcanza el nivel 5",                       icon: "crown.fill",             category: .milestone),
        Achievement(id: "xp-1000",            title: "1K XP",                   description: "Acumula 1,000 XP",                         icon: "sparkles",               category: .milestone),
        Achievement(id: "xp-5000",            title: "5K XP",                   description: "Acumula 5,000 XP",                         icon: "star.circle.fill",       category: .milestone),
    ]
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {

    @Published var unlockedIDs: Set<String>
    @Published var newlyUnlocked: Achievement?

    private let storageKey = "guitarapp.achievements"

    init() {
        let ids = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        self.unlockedIDs = Set(ids)
    }

    var unlockedAchievements: [Achievement] {
        Achievement.all.filter { unlockedIDs.contains($0.id) }
    }

    var lockedAchievements: [Achievement] {
        Achievement.all.filter { !unlockedIDs.contains($0.id) }
    }

    var progress: Double {
        Double(unlockedIDs.count) / Double(Achievement.all.count)
    }

    func unlock(_ id: String) {
        guard !unlockedIDs.contains(id) else { return }
        unlockedIDs.insert(id)
        save()
        if let achievement = Achievement.all.first(where: { $0.id == id }) {
            HapticManager.notification(.success)
            newlyUnlocked = achievement
        }
    }

    func check(gameScore: GameScore) {
        // Lessons
        if gameScore.completedLessonIDs.count >= 1 { unlock("first-lesson") }
        if gameScore.completedLessonIDs.count >= 5 { unlock("five-lessons") }
        if gameScore.completedLessonIDs.count >= Lesson.all.count { unlock("all-lessons") }

        // Milestones
        if gameScore.level >= 3 { unlock("level-3") }
        if gameScore.level >= 5 { unlock("level-5") }
        if gameScore.totalXP >= 1000 { unlock("xp-1000") }
        if gameScore.totalXP >= 5000 { unlock("xp-5000") }
    }

    private func save() {
        UserDefaults.standard.set(Array(unlockedIDs), forKey: storageKey)
    }
}
