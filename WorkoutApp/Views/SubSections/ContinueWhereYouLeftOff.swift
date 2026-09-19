//
//  PickUpWhereYouLeftOff.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-18.
//

import SwiftUI
import SwiftData


// if the app crashes or closes mid workout this allows the user to re-open and continue where they left off.
struct ContinueWhereYouLeftOff: View {
    let leftOff: WorkOutLongSave

    // environment variable for saving to the phone
    @Environment(\.modelContext) private var modelContext
    // environemnt variable for the current workout routine
    @Environment(WorkoutSession.self) private var workoutSession

    @Environment(AppSettings.self) private var appSettings

    @Environment(\.dismiss) private var dismiss

    private var sortedExercises: [Exercise] {
        leftOff.routine.exercises.sorted { $0.order < $1.order }
    }

    private var totalSetCount: Int {
        sortedExercises.reduce(0) { $0 + $1.reps.count }
    }

    private var completedSetCount: Int {
        sortedExercises.reduce(0) { $0 + $1.completedSets.count }
    }

    private var progressFraction: Double {
        totalSetCount == 0 ? 0 : Double(completedSetCount) / Double(totalSetCount)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                progressSection

                exerciseList
            }
            .padding(.horizontal, Theme.padding)
            .padding(.top, 40)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .safeAreaInset(edge: .bottom) {
            actionButtons
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .frame(width: 72, height: 72)
                .glassEffect(in: Circle())
                .padding(.bottom, 4)

            Text("Continue where you left off?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(leftOff.routine.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.primary)
                .lineLimit(1)

            Text("Started \(formattedDate(leftOff.startDate))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(completedSetCount) of \(totalSetCount) sets")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.progressBarBackground)

                    Capsule()
                        .fill(Theme.progressBar)
                        .frame(width: geometry.size.width * progressFraction)
                }
            }
            .frame(height: 8)
        }
    }

    private var exerciseList: some View {
        VStack(spacing: 10) {
            ForEach(sortedExercises) { exercise in
                exerciseRow(exercise)
            }
        }
    }

    // one exercise, its set chips laid out in a row that scrolls sideways when there are a lot of them
    @ViewBuilder
    private func exerciseRow(_ exercise: Exercise) -> some View {
        let setCount = min(exercise.reps.count, exercise.weights.count, exercise.seconds.count)
        let doneCount = exercise.completedSets.count
        let allDone = setCount > 0 && doneCount >= setCount

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: allDone ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.footnote)
                    .foregroundStyle(allDone ? Color.green : Color.secondary)

                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer()

                Text("\(doneCount)/\(setCount)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            if setCount > 0 {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(0..<setCount, id: \.self) { index in
                            setChip(exercise, index)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            } else {
                Text("No sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
        )
    }

    // a completed set gets the same green the live workout card uses, an unfinished one just an outline
    @ViewBuilder
    private func setChip(_ exercise: Exercise, _ index: Int) -> some View {
        let completed = exercise.completedSets.contains(index)
        let label = formattedSet(reps: exercise.reps[index], weight: exercise.weights[index], seconds: exercise.seconds[index], repsColumn: exercise.repsColumn, weightColumn: exercise.weightColumn, secsColumn: exercise.secsColumn, unit: appSettings.weightUnit)

        Text(label.isEmpty ? "Set \(index + 1)" : label)
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(completed ? Theme.oppositeBackground : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(completed ? Theme.checkedSetGreen : Color.clear)
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.secondary.opacity(completed ? 0 : 0.3), lineWidth: 1)
            )
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                workoutSession.start(leftOff.routine, modelContext, leftOff.startDate, true)
                dismiss()

            } label : {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.glassProminent)

            Button {
                // Clear workoutlongsave
                for stale in (try? modelContext.fetch(FetchDescriptor<WorkOutLongSave>())) ?? [] {
                    modelContext.delete(stale)
                }
                dismiss()

            } label : {
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.top, 20)
        .padding(.bottom, 8)
        // lets the list fade out under the buttons instead of cutting off hard behind them
        .background(
            LinearGradient(
                colors: [Theme.background.opacity(0), Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkOutLongSave.self, Routine.self, configurations: config)

    let sampleRoutine = Routine(name: "Push Day", exercises: [
        Exercise(name: "Barbell Bench Press", reps: [8, 8, 6], seconds: [0, 0, 0], completedSets: [0, 1, 2], weights: [135, 155, 175], restTime: 90, order: 0),
        Exercise(name: "Incline Dumbbell Press", reps: [10, 10, 8], seconds: [0, 0, 0], completedSets: [0, 1, 2], weights: [50, 55, 55], restTime: 90, order: 1),
        Exercise(name: "Overhead Press", reps: [10, 10, 8], seconds: [0, 0, 0], completedSets: [0, 1], weights: [65, 65, 75], restTime: 60, order: 2),
        Exercise(name: "Cable Fly", reps: [12, 12, 12, 10], seconds: [0, 0, 0, 0], completedSets: [0], weights: [30, 30, 35, 35], restTime: 60, order: 3),
        Exercise(name: "Dumbbell Lateral Raise", reps: [15, 15, 12, 12], seconds: [0, 0, 0, 0], completedSets: [], weights: [15, 15, 20, 20], restTime: 45, order: 4),
        Exercise(name: "Tricep Pushdown", reps: [12, 12, 10], seconds: [0, 0, 0], completedSets: [], weights: [50, 50, 60], restTime: 45, order: 5),
        Exercise(name: "Skull Crushers", reps: [12, 10, 10], seconds: [0, 0, 0], completedSets: [], weights: [65, 75, 75], restTime: 60, order: 6),
        Exercise(name: "Weighted Dips", reps: [10, 8, 8], seconds: [0, 0, 0], completedSets: [], weights: [0, 0, 0], restTime: 90, repsColumn: true, weightColumn: false, secsColumn: false, order: 7),
        Exercise(name: "Plank", reps: [1, 1], seconds: [45, 45], completedSets: [], weights: [0, 0], restTime: 45, repsColumn: false, weightColumn: false, secsColumn: true, order: 8),
        Exercise(name: "Treadmill Cooldown Walk", reps: [1], seconds: [600], completedSets: [], weights: [0], restTime: 0, repsColumn: false, weightColumn: false, secsColumn: true, order: 9)
    ])

    let sampleSave = WorkOutLongSave(
        startDate: .now.addingTimeInterval(-1200), // started 20 min ago
        routine: sampleRoutine
    )

    ContinueWhereYouLeftOff(leftOff: sampleSave)
        .modelContainer(container)
        .environment(WorkoutSession())
        .environment(AppSettings())
}
