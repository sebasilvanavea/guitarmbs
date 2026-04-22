import Foundation

// MARK: - Chord Fingering

struct ChordFingering {
    /// Fret number per string (index 0 = string 1 = high E).
    /// -1 = muted, 0 = open, 1+ = fret number.
    let frets: [Int]
    /// Finger number per string (0 = none/open, 1-4 = index to pinky).
    let fingers: [Int]
    /// The fret number shown at the left of the diagram (usually 1).
    let baseFret: Int
    /// Fret number of a barre chord, or nil.
    let barre: Int?
}

// MARK: - Chord

struct Chord: Identifiable {
    let id = UUID()
    let name: String
    let fullName: String
    let fingering: ChordFingering
    let difficulty: Int   // 1 (easy) to 5 (hard)
    let type: ChordType
    let notes: [String]   // notes in chord

    enum ChordType: String, CaseIterable {
        case major    = "Mayor"
        case minor    = "Menor"
        case dominant = "Dom 7"
        case major7   = "Maj 7"
        case minor7   = "min 7"
        case sus      = "Sus"
    }
}

// MARK: - Chord Library

extension Chord {
    static let all: [Chord] = [
        // ── Open chords ────────────────────────────────────────────────
        Chord(name: "E",
              fullName: "Mi Mayor",
              fingering: ChordFingering(frets: [0, 2, 2, 1, 0, 0], fingers: [0, 3, 2, 1, 0, 0], baseFret: 1, barre: nil),
              difficulty: 1, type: .major, notes: ["E", "B", "E", "G#", "B", "E"]),

        Chord(name: "Em",
              fullName: "Mi Menor",
              fingering: ChordFingering(frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 1, 0, 0, 0], baseFret: 1, barre: nil),
              difficulty: 1, type: .minor, notes: ["E", "B", "E", "G", "B", "E"]),

        Chord(name: "A",
              fullName: "La Mayor",
              fingering: ChordFingering(frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0], baseFret: 1, barre: nil),
              difficulty: 1, type: .major, notes: ["A", "E", "A", "C#", "E"]),

        Chord(name: "Am",
              fullName: "La Menor",
              fingering: ChordFingering(frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 3, 2, 1, 0], baseFret: 1, barre: nil),
              difficulty: 1, type: .minor, notes: ["A", "E", "A", "C", "E"]),

        Chord(name: "D",
              fullName: "Re Mayor",
              fingering: ChordFingering(frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2], baseFret: 1, barre: nil),
              difficulty: 1, type: .major, notes: ["D", "A", "D", "F#"]),

        Chord(name: "Dm",
              fullName: "Re Menor",
              fingering: ChordFingering(frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1], baseFret: 1, barre: nil),
              difficulty: 1, type: .minor, notes: ["D", "A", "D", "F"]),

        Chord(name: "G",
              fullName: "Sol Mayor",
              fingering: ChordFingering(frets: [3, 2, 0, 0, 0, 3], fingers: [2, 1, 0, 0, 0, 3], baseFret: 1, barre: nil),
              difficulty: 2, type: .major, notes: ["G", "B", "G", "D", "G", "B"]),

        Chord(name: "C",
              fullName: "Do Mayor",
              fingering: ChordFingering(frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0], baseFret: 1, barre: nil),
              difficulty: 2, type: .major, notes: ["C", "E", "G", "C", "E"]),

        Chord(name: "F",
              fullName: "Fa Mayor",
              fingering: ChordFingering(frets: [1, 1, 2, 3, 3, 1], fingers: [1, 1, 2, 4, 3, 1], baseFret: 1, barre: 1),
              difficulty: 4, type: .major, notes: ["F", "C", "F", "A", "C", "F"]),

        Chord(name: "B",
              fullName: "Si Mayor",
              fingering: ChordFingering(frets: [-1, 2, 4, 4, 4, 2], fingers: [0, 1, 3, 4, 2, 1], baseFret: 1, barre: 2),
              difficulty: 3, type: .major, notes: ["B", "F#", "B", "D#", "F#"]),

        Chord(name: "Bm",
              fullName: "Si Menor",
              fingering: ChordFingering(frets: [-1, 2, 4, 4, 3, 2], fingers: [0, 1, 3, 4, 2, 1], baseFret: 1, barre: 2),
              difficulty: 3, type: .minor, notes: ["B", "F#", "B", "D", "F#"]),

        // ── 7th chords ─────────────────────────────────────────────────
        Chord(name: "E7",
              fullName: "Mi Dom 7",
              fingering: ChordFingering(frets: [0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0], baseFret: 1, barre: nil),
              difficulty: 2, type: .dominant, notes: ["E", "B", "D", "G#", "B", "E"]),

        Chord(name: "A7",
              fullName: "La Dom 7",
              fingering: ChordFingering(frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 0, 2, 0, 1, 0], baseFret: 1, barre: nil),
              difficulty: 2, type: .dominant, notes: ["A", "E", "G", "C#", "E"]),

        Chord(name: "D7",
              fullName: "Re Dom 7",
              fingering: ChordFingering(frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 3, 1, 2], baseFret: 1, barre: nil),
              difficulty: 2, type: .dominant, notes: ["D", "A", "C", "F#"]),

        Chord(name: "G7",
              fullName: "Sol Dom 7",
              fingering: ChordFingering(frets: [3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1], baseFret: 1, barre: nil),
              difficulty: 2, type: .dominant, notes: ["G", "B", "G", "D", "G", "F"]),

        Chord(name: "Cmaj7",
              fullName: "Do Mayor 7",
              fingering: ChordFingering(frets: [-1, 3, 2, 0, 0, 0], fingers: [0, 3, 2, 0, 0, 0], baseFret: 1, barre: nil),
              difficulty: 2, type: .major7, notes: ["C", "E", "G", "B"]),

        Chord(name: "Am7",
              fullName: "La Menor 7",
              fingering: ChordFingering(frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 0, 2, 0, 1, 0], baseFret: 1, barre: nil),
              difficulty: 2, type: .minor7, notes: ["A", "E", "G", "C", "E"]),

        Chord(name: "Dsus4",
              fullName: "Re Sus4",
              fingering: ChordFingering(frets: [-1, -1, 0, 2, 3, 3], fingers: [0, 0, 0, 1, 3, 4], baseFret: 1, barre: nil),
              difficulty: 2, type: .sus, notes: ["D", "A", "D", "G"])
    ]
}
