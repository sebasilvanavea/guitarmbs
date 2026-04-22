import SwiftUI

/// Draws a traditional guitar chord diagram using SwiftUI Canvas.
struct ChordDiagramView: View {

    let chord: Chord
    var showLabel: Bool = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let topPad: CGFloat  = 22   // room for open/muted symbols
            let leftPad: CGFloat = 18
            let rightPad: CGFloat = 6
            let gridW = w - leftPad - rightPad
            let gridH = h - topPad - 8
            let sS = gridW / 5   // string spacing (6 strings → 5 gaps)
            let fS = gridH / 4   // fret spacing (4 visible frets)

            Canvas { ctx, _ in

                // ── Open / muted markers (above nut) ────────────────
                for (i, fret) in chord.fingering.frets.enumerated() {
                    let x = leftPad + CGFloat(i) * sS
                    let y: CGFloat = 11
                    if fret == -1 {
                        // X  – muted string
                        let r: CGFloat = 6
                        ctx.stroke(
                            Path { p in
                                p.move(to: CGPoint(x: x - r, y: y - r))
                                p.addLine(to: CGPoint(x: x + r, y: y + r))
                                p.move(to: CGPoint(x: x + r, y: y - r))
                                p.addLine(to: CGPoint(x: x - r, y: y + r))
                            },
                            with: .color(.red),
                            lineWidth: 1.5
                        )
                    } else if fret == 0 {
                        // O  – open string
                        ctx.stroke(
                            Path { p in
                                p.addEllipse(in: CGRect(x: x - 6, y: y - 6, width: 12, height: 12))
                            },
                            with: .color(.primary),
                            lineWidth: 1.5
                        )
                    }
                }

                // ── Nut (thick bar at top if base fret = 1) ─────────
                let nutY = topPad
                if chord.fingering.baseFret == 1 {
                    ctx.fill(
                        Path { p in
                            p.addRect(CGRect(x: leftPad - 1, y: nutY - 3,
                                            width: gridW + 2, height: 5))
                        },
                        with: .color(.primary)
                    )
                }

                // ── Fret lines ───────────────────────────────────────
                for i in 0...4 {
                    let y = nutY + CGFloat(i) * fS
                    ctx.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: leftPad, y: y))
                            p.addLine(to: CGPoint(x: leftPad + gridW, y: y))
                        },
                        with: .color(.primary.opacity(0.35)),
                        lineWidth: 1
                    )
                }

                // ── String lines (6 strings) ─────────────────────────
                for i in 0...5 {
                    let x = leftPad + CGFloat(i) * sS
                    let thickness: CGFloat = i == 5 ? 2.5 : (i == 4 ? 2 : 1)   // thicker for bass
                    ctx.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: x, y: nutY))
                            p.addLine(to: CGPoint(x: x, y: nutY + gridH))
                        },
                        with: .color(.primary.opacity(0.6)),
                        lineWidth: thickness
                    )
                }

                // ── Barre bar ────────────────────────────────────────
                if let barre = chord.fingering.barre {
                    let adj = barre - chord.fingering.baseFret + 1
                    let y   = nutY + (CGFloat(adj) - 0.5) * fS
                    ctx.fill(
                        Path { p in
                            p.addRoundedRect(
                                in: CGRect(x: leftPad - 4, y: y - 11,
                                           width: gridW + 8, height: 22),
                                cornerSize: CGSize(width: 11, height: 11)
                            )
                        },
                        with: .color(.orange.opacity(0.85))
                    )
                }

                // ── Finger dots ──────────────────────────────────────
                for (i, fret) in chord.fingering.frets.enumerated() {
                    guard fret > 0 else { continue }
                    let adj = fret - chord.fingering.baseFret + 1
                    let x = leftPad + CGFloat(i) * sS
                    let y = nutY + (CGFloat(adj) - 0.5) * fS
                    let r: CGFloat = min(sS, fS) * 0.38

                    ctx.fill(
                        Path { p in
                            p.addEllipse(in: CGRect(x: x - r, y: y - r,
                                                    width: r * 2, height: r * 2))
                        },
                        with: .color(.orange)
                    )

                    // Finger number inside dot
                    let finger = chord.fingering.fingers[i]
                    if finger > 0 {
                        ctx.draw(
                            Text("\(finger)")
                                .font(.system(size: r * 1.1, weight: .bold))
                                .foregroundColor(.white),
                            at: CGPoint(x: x, y: y),
                            anchor: .center
                        )
                    }
                }

                // ── Base fret label (if not starting at fret 1) ──────
                if chord.fingering.baseFret > 1 {
                    ctx.draw(
                        Text("\(chord.fingering.baseFret)fr")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary),
                        at: CGPoint(x: leftPad - 4, y: nutY + fS * 0.5),
                        anchor: .trailing
                    )
                }
            }
        }
    }
}
