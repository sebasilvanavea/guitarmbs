import SwiftUI

struct ChordsView: View {

    @State private var selectedChord: Chord?
    @State private var filterType: Chord.ChordType? = nil
    @State private var searchText = ""

    private var filtered: [Chord] {
        Chord.all.filter { chord in
            let matchSearch = searchText.isEmpty
                || chord.name.localizedCaseInsensitiveContains(searchText)
                || chord.fullName.localizedCaseInsensitiveContains(searchText)
            let matchType = filterType == nil || chord.type == filterType
            return matchSearch && matchType
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // ── Search bar ───────────────────────────────────────
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar acorde...", text: $searchText)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                // ── Type filter chips ────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TypeChip(label: "Todos", active: filterType == nil) {
                            filterType = nil
                        }
                        ForEach(Chord.ChordType.allCases, id: \.rawValue) { type in
                            TypeChip(label: type.rawValue, active: filterType == type) {
                                filterType = filterType == type ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                // ── Chord grid ───────────────────────────────────────
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 16
                    ) {
                        ForEach(filtered) { chord in
                            ChordCard(chord: chord)
                                .onTapGesture { selectedChord = chord }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Acordes")
            .sheet(item: $selectedChord) { chord in
                ChordDetailSheet(chord: chord)
            }
        }
    }
}

// MARK: - Chip

struct TypeChip: View {
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(active ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(active ? Color.orange : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

// MARK: - Chord Card

struct ChordCard: View {
    let chord: Chord

    var body: some View {
        VStack(spacing: 10) {
            ChordDiagramView(chord: chord)
                .frame(height: 130)
                .padding(.horizontal, 6)

            VStack(spacing: 2) {
                Text(chord.name)
                    .font(.title2.bold())
                Text(chord.fullName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Difficulty stars
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= chord.difficulty ? "star.fill" : "star")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                }
            }

            Text(chord.type.rawValue)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.85))
                .cornerRadius(6)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Chord Detail Sheet

struct ChordDetailSheet: View {
    let chord: Chord
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {

                    // Large diagram
                    ChordDiagramView(chord: chord)
                        .frame(width: 240, height: 240)
                        .padding(.top)

                    // Notes in chord
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notas del acorde", systemImage: "music.note")
                            .font(.headline)

                        HStack(spacing: 10) {
                            ForEach(chord.notes, id: \.self) { note in
                                Text(note)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 42, height: 42)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal)

                    // String-by-string instructions
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Posición de dedos", systemImage: "hand.raised")
                            .font(.headline)

                        let stringNames = ["1ª (E agudo)", "2ª (B)", "3ª (G)", "4ª (D)", "5ª (A)", "6ª (E grave)"]
                        ForEach(0..<6, id: \.self) { i in
                            let fret = chord.fingering.frets[i]
                            HStack {
                                Text(stringNames[i])
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Group {
                                    if fret == -1 {
                                        Label("Apagada", systemImage: "xmark")
                                            .foregroundColor(.red)
                                    } else if fret == 0 {
                                        Label("Al aire", systemImage: "circle")
                                            .foregroundColor(.green)
                                    } else {
                                        Text("Traste \(fret)")
                                    }
                                }
                                .font(.subheadline)
                            }
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal)

                    // Tips
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Consejo", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text(tipForChord(chord))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("\(chord.name)  –  \(chord.fullName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func tipForChord(_ chord: Chord) -> String {
        if let _ = chord.fingering.barre {
            return "Este acorde usa cejilla. Asegúrate de que el dedo índice presione todas las cuerdas del mismo traste con fuerza uniforme."
        }
        switch chord.difficulty {
        case 1: return "¡Buen comienzo! Practica este acorde hasta que suene limpio antes de pasar al siguiente."
        case 2: return "Curva los dedos para no tapar cuerdas adyacentes. La postura del pulgar en el mástil es clave."
        default: return "Ten paciencia. Los acordes difíciles requieren semanas de práctica diaria. ¡Tú puedes!"
        }
    }
}
