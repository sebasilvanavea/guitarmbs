import Foundation

// MARK: - Note Frequency Utilities

struct NoteFrequencyHelper {

    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// Detect note name, octave and tuning deviation (cents) from a raw frequency.
    static func detectNote(from frequency: Double) -> (note: String, octave: Int, cents: Double)? {
        guard frequency > 20 && frequency < 5000 else { return nil }

        let A4: Double = 440.0
        let semitonesFromA4 = 12.0 * log2(frequency / A4)
        let roundedSemitones = round(semitonesFromA4)
        let cents = (semitonesFromA4 - roundedSemitones) * 100.0

        let midiNote = Int(roundedSemitones) + 69
        let octave = (midiNote / 12) - 1
        let noteIndex = ((midiNote % 12) + 12) % 12
        let noteName = noteNames[noteIndex]

        return (noteName, octave, cents)
    }

    /// Get the frequency for a given note name and octave.
    static func frequency(note: String, octave: Int) -> Double {
        guard let idx = noteNames.firstIndex(of: note) else { return 440 }
        let midiNote = (octave + 1) * 12 + idx
        return 440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }

    /// Standard guitar open-string tuning (string 1 = high E).
    static let guitarStrings: [(string: Int, note: String, octave: Int)] = [
        (1, "E", 4),
        (2, "B", 3),
        (3, "G", 3),
        (4, "D", 3),
        (5, "A", 2),
        (6, "E", 2)
    ]

    /// Returns the note name at a given string (1-6) and fret (0-24).
    static func noteOnFret(string: Int, fret: Int) -> String {
        let openNotes = ["E", "B", "G", "D", "A", "E"] // strings 1-6
        guard string >= 1 && string <= 6, fret >= 0 && fret <= 24 else { return "?" }
        let openNote = openNotes[string - 1]
        guard let baseIndex = noteNames.firstIndex(of: openNote) else { return "?" }
        return noteNames[(baseIndex + fret) % 12]
    }

    // MARK: - Scales

    struct Scale {
        let name: String
        let notes: [String]
        let description: String
    }

    static let commonScales: [Scale] = [
        Scale(name: "Pentatónica menor (Am)",
              notes: ["A", "C", "D", "E", "G"],
              description: "La escala más usada en rock y blues. 5 notas."),
        Scale(name: "Pentatónica mayor (G)",
              notes: ["G", "A", "B", "D", "E"],
              description: "Sonido brillante y positivo. Ideal para country y pop."),
        Scale(name: "Escala Mayor (C)",
              notes: ["C", "D", "E", "F", "G", "A", "B"],
              description: "La escala fundamental. Base de toda la teoría musical."),
        Scale(name: "Escala Menor Natural (Am)",
              notes: ["A", "B", "C", "D", "E", "F", "G"],
              description: "Sonido melancólico y expresivo. Muy usada en rock y clásica."),
        Scale(name: "Blues (A)",
              notes: ["A", "C", "D", "D#", "E", "G"],
              description: "La escala del blues. Esa nota azul D# le da el carácter.")
    ]
}
