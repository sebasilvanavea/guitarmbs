import Foundation
import SwiftUI

// MARK: - Lesson Category

enum LessonCategory: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case basics  = "Básicos"
    case chords  = "Acordes"
    case scales  = "Escalas"
    case songs   = "Canciones"
    case theory  = "Teoría"

    var icon: String {
        switch self {
        case .basics:  return "guitars.fill"
        case .chords:  return "hand.raised.fill"
        case .scales:  return "arrow.up.right"
        case .songs:   return "music.note"
        case .theory:  return "book.fill"
        }
    }

    var color: Color {
        switch self {
        case .basics:  return .blue
        case .chords:  return .orange
        case .scales:  return .purple
        case .songs:   return .green
        case .theory:  return .red
        }
    }
}

// MARK: - Lesson Step

enum LessonStepContent {
    case text(String)
    case chord(String)                          // chord name
    case scale([String])                        // note names
    case fretboardNote(string: Int, fret: Int)  // position to identify
    case exercise(String)
}

struct LessonStep: Identifiable {
    let id: String
    let instruction: String
    let content: LessonStepContent

    init(id: String = UUID().uuidString, instruction: String, content: LessonStepContent) {
        self.id = id
        self.instruction = instruction
        self.content = content
    }
}

// MARK: - Lesson

struct Lesson: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: LessonCategory
    let difficulty: Int   // 1-5
    let steps: [LessonStep]
    let xpReward: Int
}

// MARK: - Lesson Library

extension Lesson {
    static let all: [Lesson] = [

        // ── Basics ────────────────────────────────────────────────────
        Lesson(
            id: "lesson-guitar-parts",
            title: "Partes de la guitarra",
            description: "Conoce tu instrumento antes de tocar",
            category: .basics, difficulty: 1,
            steps: [
                LessonStep(instruction: "La guitarra tiene 6 cuerdas. De más gruesa a más delgada: E (Mi), A (La), D (Re), G (Sol), B (Si), E (Mi agudo).", content: .text("")),
                LessonStep(instruction: "Los trastes dividen el mástil en semitonos. Cada traste sube 1 semitono en altura.", content: .text("")),
                LessonStep(instruction: "Postura correcta: sujeta el mástil con el pulgar detrás y los dedos curvados, nunca aplanes la muñeca.", content: .text(""))
            ],
            xpReward: 50
        ),

        Lesson(
            id: "lesson-read-tab",
            title: "Cómo leer tablatura (TAB)",
            description: "Entiende el sistema de notación para guitarra",
            category: .basics, difficulty: 1,
            steps: [
                LessonStep(instruction: "Una tablatura tiene 6 líneas, una por cuerda. La línea de abajo es la 6a cuerda (E grave).", content: .text("")),
                LessonStep(instruction: "El número sobre la línea indica el traste. '0' = cuerda al aire, '5' = traste 5.", content: .text("")),
                LessonStep(instruction: "Lee la tablatura de izquierda a derecha, igual que una partitura.", content: .text(""))
            ],
            xpReward: 50
        ),

        // ── Chords ────────────────────────────────────────────────────
        Lesson(
            id: "lesson-first-chord-em",
            title: "Tu primer acorde: Em",
            description: "El acorde más fácil de la guitarra",
            category: .chords, difficulty: 1,
            steps: [
                LessonStep(instruction: "Em solo necesita 2 dedos. Dedo medio en la cuerda 5 traste 2, dedo anular en la cuerda 4 traste 2.", content: .chord("Em")),
                LessonStep(instruction: "Rasguea todas las cuerdas al aire. Todas deben sonar limpias. Ajusta los dedos si alguna cuerda queda apagada.", content: .chord("Em"))
            ],
            xpReward: 75
        ),

        Lesson(
            id: "lesson-chords-am-e",
            title: "Acordes Am y E",
            description: "Dos acordes que suenan increíble juntos",
            category: .chords, difficulty: 1,
            steps: [
                LessonStep(instruction: "Am: dedo índice en cuerda 2 traste 1, medio en cuerda 4 traste 2, anular en cuerda 3 traste 2.", content: .chord("Am")),
                LessonStep(instruction: "E Mayor: dedo índice en cuerda 3 traste 1, medio en cuerda 5 traste 2, anular en cuerda 4 traste 2.", content: .chord("E")),
                LessonStep(instruction: "Practica la transición: Am → E → Am → E. Empieza muy lento.", content: .text(""))
            ],
            xpReward: 100
        ),

        Lesson(
            id: "lesson-progression-145",
            title: "La progresión I-IV-V",
            description: "La base de miles de canciones",
            category: .chords, difficulty: 2,
            steps: [
                LessonStep(instruction: "En la tonalidad de G: G (I) → C (IV) → D (V) → G. Esta progresión funciona en pop, rock, country y más.", content: .text("")),
                LessonStep(instruction: "Practica: G → C → D → G. Usa metrónomo a 60 BPM.", content: .chord("G")),
                LessonStep(instruction: "¡Intenta este ritmo: 1-2-3-4, cambia acorde en el '1' de cada compás.", content: .text(""))
            ],
            xpReward: 125
        ),

        // ── Scales ────────────────────────────────────────────────────
        Lesson(
            id: "lesson-pentatonic-minor",
            title: "Escala Pentatónica menor",
            description: "La escala favorita del rock y blues",
            category: .scales, difficulty: 2,
            steps: [
                LessonStep(instruction: "La pentatónica menor de Am tiene 5 notas: A, C, D, E, G. Empiezas en el traste 5 de la 6a cuerda.", content: .scale(["A", "C", "D", "E", "G"])),
                LessonStep(instruction: "El patrón en el mástil: cuerda 6 trastes 5-8, cuerda 5 trastes 5-7, cuerda 4 trastes 5-7, cuerda 3 trastes 5-7, cuerda 2 trastes 5-8, cuerda 1 trastes 5-8.", content: .text("")),
                LessonStep(instruction: "Sube y baja la escala con metrónomo. Empieza a 60 BPM y aumenta poco a poco.", content: .text(""))
            ],
            xpReward: 150
        ),

        Lesson(
            id: "lesson-major-scale",
            title: "Escala Mayor",
            description: "La base de toda la teoría musical",
            category: .scales, difficulty: 3,
            steps: [
                LessonStep(instruction: "La escala mayor tiene 7 notas con el patrón Tono-Tono-Semitono-Tono-Tono-Tono-Semitono.", content: .scale(["C", "D", "E", "F", "G", "A", "B"])),
                LessonStep(instruction: "En Do: C-D-E-F-G-A-B-C. El patrón de intervalos es siempre el mismo sin importar la tonalidad.", content: .text("")),
                LessonStep(instruction: "Practica la escala de G mayor: G-A-B-C-D-E-F#-G. Nota que hay un F sostenido.", content: .scale(["G", "A", "B", "C", "D", "E", "F#"]))
            ],
            xpReward: 175
        ),

        // ── Theory ────────────────────────────────────────────────────
        Lesson(
            id: "lesson-fretboard-notes",
            title: "Las notas en el mástil",
            description: "Aprende dónde está cada nota",
            category: .theory, difficulty: 2,
            steps: [
                LessonStep(instruction: "La cuerda 6 al aire es E. Traste 1 = F, traste 2 = F#, traste 3 = G... y así hasta el traste 12, que vuelve a ser E.", content: .fretboardNote(string: 6, fret: 0)),
                LessonStep(instruction: "Los trastes 5 y 7 tienen puntos marcados en el mástil para ayudarte a orientarte. El traste 12 tiene doble punto.", content: .text("")),
                LessonStep(instruction: "Memoriza las notas en trastes 5 y 7 de cada cuerda: son las más usadas.", content: .fretboardNote(string: 1, fret: 5))
            ],
            xpReward: 150
        ),

        // ── Songs ─────────────────────────────────────────────────────
        Lesson(
            id: "lesson-smoke-water",
            title: "Smoke on the Water (intro)",
            description: "El riff más famoso del rock",
            category: .songs, difficulty: 2,
            steps: [
                LessonStep(instruction: "Este riff usa la cuerda 4. Empieza en el traste 0 (al aire) y sigue el patrón: 0-3-5, 0-3-6-5, 0-3-5, 3-0.", content: .text("")),
                LessonStep(instruction: "Toca lento primero: cuerda 4 abierta → traste 3 → traste 5. Repite hasta que suene limpio.", content: .fretboardNote(string: 4, fret: 0)),
                LessonStep(instruction: "Aumenta el tempo gradualmente. El original está a 112 BPM. ¡No hay prisa!", content: .text(""))
            ],
            xpReward: 200
        )
    ]
}
