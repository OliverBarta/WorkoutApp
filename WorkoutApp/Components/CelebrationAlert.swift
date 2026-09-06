//
//  CelebrationAlert.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-02.
//

import SwiftUI

// the card shown when a set beats the personal best for that exercise
struct CelebrationAlert: View {
    let exerciseName: String
    // comes in as pounds, formattedWeight converts it to whatever unit is picked
    let weight: Double

    let onDismiss: () -> Void

    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        ZStack {
            Fireworks()
                .allowsHitTesting(false)
            
            VStack(spacing: 12) {
                if weight >= 225 && exerciseName == "Barbell bench press" {
                    Text("YOUR THE GOAT! New PB")
                        .font(.headline)
                } else {
                    Text("New PB")
                        .font(.headline)
                }

                Text(exerciseName)
                    .foregroundColor(.secondary)

                Text("\(formattedWeight(weight, unit: appSettings.weightUnit)) \(appSettings.weightUnit.label)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.orange)

                Button {
                    onDismiss()
                } label: {
                    Text("Nice!")
                        .frame(maxWidth: .infinity)
                        .padding(5)
                }
                .buttonStyle(.glassProminent)
                .padding(.top, 4)
                
                Text("This is only saved once the workout is logged.")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: 270)
            .glassEffect(in: RoundedRectangle(cornerRadius: 14))
        }
        
        
        
    }
}

// Fully AI fireworks

// one burst of sparks flying out from a single point
private struct Burst {
    // where it goes off, 0...1 across and down the card
    let centerX: Double
    let centerY: Double
    let color: Color
    // seconds into the show before this one goes off
    let delay: Double
    // how far its sparks travel, in points
    let radius: Double
    let sparkCount: Int
    // rotates the sparks so that no two bursts line up
    let angleOffset: Double
}


// the fireworks, played through once when the card appears. TimelineView redraws every frame and what
// gets drawn is purely a function of how long the card has been up, so there is no per spark animation
// state to keep in sync
private struct Fireworks: View {
    // how long one burst takes from going off to fully faded
    private static let burstLength: Double = 1.2

    // the canvas fills the screen but the card is only about 270 by 200 in the middle of it, so every
    // burst sits in the band above the card (y up to 0.22) or the band below it (y from 0.76) to keep
    // the sparks from going off behind the text
    private static let bursts: [Burst] = [
        Burst(centerX: 0.18, centerY: 0.16, color: Theme.orange, delay: 0.0, radius: 46, sparkCount: 12, angleOffset: 0.0),
        Burst(centerX: 0.80, centerY: 0.82, color: Theme.gold, delay: 0.13, radius: 42, sparkCount: 11, angleOffset: 0.26),
        Burst(centerX: 0.52, centerY: 0.33, color: .yellow, delay: 0.26, radius: 38, sparkCount: 10, angleOffset: 0.50),
        Burst(centerX: 0.24, centerY: 0.86, color: Theme.primary, delay: 0.39, radius: 44, sparkCount: 12, angleOffset: 0.12),
        Burst(centerX: 0.86, centerY: 0.30, color: .pink, delay: 0.52, radius: 40, sparkCount: 11, angleOffset: 0.40),
        Burst(centerX: 0.46, centerY: 0.90, color: .green, delay: 0.65, radius: 50, sparkCount: 13, angleOffset: 0.18),
        Burst(centerX: 0.10, centerY: 0.22, color: Theme.gold, delay: 0.78, radius: 36, sparkCount: 10, angleOffset: 0.62),
        Burst(centerX: 0.68, centerY: 0.77, color: Theme.orange, delay: 0.91, radius: 44, sparkCount: 12, angleOffset: 0.30),
        Burst(centerX: 0.34, centerY: 0.19, color: .cyan, delay: 1.04, radius: 40, sparkCount: 11, angleOffset: 0.08),
        Burst(centerX: 0.90, centerY: 0.88, color: .yellow, delay: 1.17, radius: 38, sparkCount: 10, angleOffset: 0.55),
        Burst(centerX: 0.66, centerY: 0.13, color: Theme.primary, delay: 1.30, radius: 42, sparkCount: 12, angleOffset: 0.22),
        Burst(centerX: 0.12, centerY: 0.79, color: .pink, delay: 1.40, radius: 46, sparkCount: 13, angleOffset: 0.44),
    ]

    // the whole show, from the first burst going off to the last spark fading out
    private static let showLength: Double = (bursts.map(\.delay).max() ?? 0) + burstLength

    // when the card appeared, which everything is measured from
    @State private var start = Date()

    // flipped once the last spark has faded so the timeline stops redrawing for nothing
    @State private var finished = false

    var body: some View {
        TimelineView(.animation(paused: finished)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSince(start)

                for burst in Self.bursts {
                    let elapsed = now - burst.delay

                    // skip the bursts that havent gone off yet and the ones already faded out
                    guard elapsed >= 0, elapsed <= Self.burstLength else { continue }

                    draw(burst, progress: elapsed / Self.burstLength, in: &context, size: size)
                }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(Self.showLength))
            finished = true
        }
    }

    private func draw(_ burst: Burst, progress: Double, in context: inout GraphicsContext, size: CGSize) {
        // the sparks shoot out fast then coast, so the distance eases out instead of moving evenly
        let distance = burst.radius * (1 - pow(1 - progress, 3))

        // and they sag on the way out, like real ones
        let drop = 16 * progress * progress

        let fade = 1 - progress

        // they shrink as they fade too
        let sparkSize = 4.0 * (1 - progress * 0.6)

        let originX = burst.centerX * size.width
        let originY = burst.centerY * size.height

        for spark in 0..<burst.sparkCount {
            let angle = burst.angleOffset + (Double(spark) / Double(burst.sparkCount)) * 2 * .pi

            let x = originX + cos(angle) * distance
            let y = originY + sin(angle) * distance + drop

            let rect = CGRect(x: x - sparkSize / 2, y: y - sparkSize / 2, width: sparkSize, height: sparkSize)

            context.fill(Path(ellipseIn: rect), with: .color(burst.color.opacity(fade)))
        }
    }
}


#Preview {
    CelebrationAlert(exerciseName: "Barbell bench press", weight: 225) {}
        .environment(AppSettings())
}
