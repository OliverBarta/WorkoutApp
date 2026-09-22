//
//  workoutEndSummaryView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-21.
//
    
import SwiftUI
import SwiftData

struct WorkoutEndSummaryView: View {
    @Bindable var routine: Routine
    
    @Environment(WorkoutSession.self) private var workoutSession

    @Environment(\.modelContext) private var modelContext

    @Environment(AuthManager.self) private var authManager
    
    @Environment(AppSettings.self) private var appSettings

    @Query(sort: \WorkoutHistoryEntry.dateCompleted, order: .reverse) private var history: [WorkoutHistoryEntry]
    
    // query makes routines the same everywhere so just type this and the variable is the same
    @Query(sort: \Routine.order) private var routines: [Routine]
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var errorMessage: String = ""

    // the log button's fill: yellow only in the top leading corner, green across the rest of it
    private var logGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.yellow, location: 0),
                .init(color: Color.green, location: 0.9),
                .init(color: Color.green, location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private let calendar = Calendar.current

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    // one exercise whose best completed weight this workout beat the stored best
    private struct NewPersonalBest: Identifiable {
        let id: String// the lowercased exercise name, the same key personalBests uses
        let name: String
        let weight: Double
        let previous: Double
    }

    // appSettings.personalBests is still the pre-workout one here, since it only gets written
    // by uploadRoutineToHistorySupabase once a log button is pressed
    private var newPersonalBests: [NewPersonalBest] {
        var bests: [String: NewPersonalBest] = [:]

        for exercise in routine.exercises where exercise.weightColumn {
            let key = exercise.name.lowercased()
            let previous = appSettings.personalBests[key] ?? 0

            let heaviest = exercise.completedSets
                .filter { exercise.weights.indices.contains($0) }
                .map { exercise.weights[$0] }
                .max()

            guard let heaviest, heaviest > previous else { continue }

            // the same exercise can sit in a routine twice, so only the heavier of the two counts
            if let existing = bests[key], existing.weight >= heaviest { continue }

            bests[key] = NewPersonalBest(id: key, name: exercise.name, weight: heaviest, previous: previous)
        }

        return bests.values.sorted { $0.weight > $1.weight }
    }

    // every day already in history, plus today once this workout has a completed set in it
    private var loggedDays: Set<Date> {
        var days = Set(history.map { calendar.startOfDay(for: $0.dateCompleted) })

        if routine.exercises.contains(where: { !$0.completedSets.isEmpty }) {
            days.insert(calendar.startOfDay(for: Date()))
        }

        return days
    }

    private var daysThisMonth: Int {
        loggedDays.filter { calendar.isDate($0, equalTo: Date(), toGranularity: .month) }.count
    }

    // nil for the blanks before the 1st, so the grid starts on the right weekday
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: Date()),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        var days: [Date?] = Array(repeating: nil, count: (firstWeekday - calendar.firstWeekday + 7) % 7)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? monthInterval.end
        }

        return days
    }

    // rotated so the first column is whatever day the user's calendar starts its week on
    private var weekdayInitials: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let offset = calendar.firstWeekday - 1

        return Array(symbols[offset...] + symbols[..<offset])
    }
    
    // how the routine ended up differing from the copies taken when the workout started
    private struct RoutineChanges {
        let added: [String]
        let edited: [String]
        let removed: [String]
    }

    private var routineChanges: RoutineChanges {
        // grouped by name, so a routine holding the same exercise twice still pairs up one for one
        var unmatched: [String: [Exercise]] = [:]

        for exercise in workoutSession.originalRoutineExercises {
            unmatched[exercise.name, default: []].append(exercise)
        }

        var added: [String] = []
        var edited: [String] = []

        for exercise in routine.exercises.sorted(by: { $0.order < $1.order }) {
            guard var originals = unmatched[exercise.name], !originals.isEmpty else {
                added.append(exercise.name)
                continue
            }

            // an untouched original is taken first, so only genuinely changed exercises count as edited
            if let index = originals.firstIndex(where: { sameSetup($0, exercise) }) {
                originals.remove(at: index)
            } else {
                originals.removeFirst()
                edited.append(exercise.name)
            }

            unmatched[exercise.name] = originals
        }

        // whatever original never got paired off was removed during the workout
        let removed = unmatched.values
            .flatMap { $0 }
            .sorted { $0.order < $1.order }
            .map { $0.name }

        return RoutineChanges(added: added, edited: edited, removed: removed)
    }

    // order is left out on purpose: moving an exercise up the list is not an edit to the exercise itself
    private func sameSetup(_ a: Exercise, _ b: Exercise) -> Bool {
        a.reps == b.reps && a.weights == b.weights && a.seconds == b.seconds && a.restTime == b.restTime && a.repsColumn == b.repsColumn && a.weightColumn == b.weightColumn && a.secsColumn == b.secsColumn
    }

    // whether or not the routine changed from the original routine the workout started with
    @State private var workOutChanged: Bool = true

    var body: some View {
        VStack {
            ScrollView {

                Rectangle()
                    .padding(.top, 35)
                    .opacity(0)
                
                statsSection
                    .padding(.bottom, 5)

                newPersonalBestsSection
                    .padding(.bottom, 5)

                calendarSection
                    .padding(.bottom, 5)

                routineChangesSection
                    .padding(.bottom, 5)

                if workOutChanged {
                    Text("Would you like to log this workout and/or update this routine?")
                        .font(.headline)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Would you like to log this routine?")
                        .font(.headline)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("No changes to the routine so no update button")
                        .font(.caption)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if workOutChanged {
                    Button {
                        // saves routine to history and updates the routine
                        
                        if let workoutRoutine = workoutSession.workoutRoutine,
                           let startDate = workoutSession.workoutStartDate {
                            
                            let duration = Int(Date().timeIntervalSince(startDate))
                            let historySnapshot = history
                            
                            
                            saveRoutineToHistory(workoutRoutine, duration, modelContext, appSettings.personalBests)
                            
                            let routineTemporary = workoutRoutine.copy()// Made so the asynchronus functions can run without getting effected by other functions changing routine
                            
                            Task {
                                do {
                                    try await uploadRoutineToSupabase(routineTemporary, routineId: routine.id)
                                    try await uploadRoutineToHistorySupabase(routineTemporary, routineId: routine.id, duration: duration, appSettings: appSettings)
                                    
                                    
                                } catch {
                                    print("History upload error: \(error)")
                                    errorMessage = "Upload failed: \(error)"
                                }
                            }
                            
                            Task {
                                do {
                                    try await authManager.updateStreakAfterWorkout(history: historySnapshot)
                                } catch {
                                    print("Streak update failed: \(error)")
                                    errorMessage = "Streak update failed: \(error)"
                                }
                            }
                            
                            // Clears completed sets
                            routine.exercises = workoutRoutine.exercises.map { $0.copyCompletedSetsToZero() }
                            
                        }
                        
                        MoveThisRoutineToTheEnd()
                        
                        // ends workout
                        workoutSession.end(modelContext)
                        dismiss()
                    } label : {
                        Text("Log and update")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.green)
                    .padding(.horizontal)
                    
                    Button {
                        // saves routine to history doesn't update routine
                        
                        // saves to local storage, uploads to supabase, then updates the streak.
                        if let workoutRoutine = workoutSession.workoutRoutine,
                           let startDate = workoutSession.workoutStartDate {
                            
                            let duration = Int(Date().timeIntervalSince(startDate))
                            let historySnapshot = history
                            let routineTemporary = workoutRoutine.copy()// Made so the asynchronus functions can run without getting effected by other functions changing routine
                            
                            saveRoutineToHistory(workoutRoutine, duration, modelContext, appSettings.personalBests)
                            
                            Task {
                                do {
                                    try await uploadRoutineToHistorySupabase(routineTemporary, routineId: routine.id, duration: duration, appSettings: appSettings)
                                    
                                } catch {
                                    print("Routine upload error: \(error)")
                                    errorMessage = "Upload failed: \(error)"
                                }
                            }
                            
                            Task {
                                do {
                                    try await authManager.updateStreakAfterWorkout(history: historySnapshot)
                                } catch {
                                    print("Streak update failed: \(error)")
                                    errorMessage = "Streak update failed: \(error)"
                                }
                            }
                            
                            // resets routinen back to original AFTER the above
                            routine.exercises = workoutSession.originalRoutineExercises.map { $0.copy() }
                        }
                        
                        MoveThisRoutineToTheEnd()
                        
                        // ends workout
                        workoutSession.end(modelContext)
                        dismiss()
                    } label : {
                        Text("Log, don't update")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.yellow)
                    .padding(.horizontal)
                } else {
                    Button {
                        // saves routine to history doesn't update routine
                        
                        // saves to local storage, uploads to supabase, then updates the streak.
                        if let workoutRoutine = workoutSession.workoutRoutine,
                           let startDate = workoutSession.workoutStartDate {
                            
                            let duration = Int(Date().timeIntervalSince(startDate))
                            let historySnapshot = history
                            let routineTemporary = workoutRoutine.copy()// Made so the asynchronus functions can run without getting effected by other functions changing routine
                            
                            saveRoutineToHistory(workoutRoutine, duration, modelContext, appSettings.personalBests)
                            
                            Task {
                                do {
                                    try await uploadRoutineToHistorySupabase(routineTemporary, routineId: routine.id, duration: duration, appSettings: appSettings)
                                    
                                } catch {
                                    print("Routine upload error: \(error)")
                                    errorMessage = "Upload failed: \(error)"
                                }
                            }
                            
                            Task {
                                do {
                                    try await authManager.updateStreakAfterWorkout(history: historySnapshot)
                                } catch {
                                    print("Streak update failed: \(error)")
                                    errorMessage = "Streak update failed: \(error)"
                                }
                            }
                            
                            // resets routinen back to original AFTER the above
                            routine.exercises = workoutSession.originalRoutineExercises.map { $0.copy() }
                        }
                        
                        MoveThisRoutineToTheEnd()
                        
                        // ends workout
                        workoutSession.end(modelContext)
                        dismiss()
                    } label : {
                        Text("Log")
                            .frame(maxWidth: .infinity)
                            .padding(22)
                            .background(logGradient)
                            .clipShape(Capsule())
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.plain)// the gradient is the fill, so the glass style would only sit on top of it
                    .padding(.horizontal)
                }
                
                Button {
                    
                    // resets routinen back to original
                    routine.exercises = workoutSession.originalRoutineExercises.map { $0.copy() }
                    
                    workoutSession.end(modelContext)
                    dismiss()
                } label : {
                    if workOutChanged{
                        Text("Don't log or update")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(Color.black)
                    } else {
                        Text("Don't log")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(Color.black)
                    }
                }
                .buttonStyle(.glassProminent)
                .tint(Color.red)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)

        }
        .overlay {
            VStack {
                ZStack {
                    Text("Summary")
                        .headerStyle()
                        .padding(.horizontal, 65)

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .padding(5)
                    }
                    .buttonStyle(.glass)
                    .foregroundColor(Theme.oppositeBackground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                TopPopUp(message: $errorMessage)

                Spacer()
            }
        }
        .task {
            workOutChanged = CheckIfTheRoutineChanged()
        }
        
    }

    private func CheckIfTheRoutineChanged() -> Bool {
        if routine.exercises.count != workoutSession.originalRoutineExercises.count {
            return true
        }
        
        // exercises are sorted the same way-by order and if there is a glitch with duplicate orders it goes by name. This is so they are indexed correctly
        let newExercises = routine.exercises.sorted { $0.order == $1.order ? $0.name < $1.name : $0.order < $1.order }
        let ogExercises  = workoutSession.originalRoutineExercises.sorted { $0.order == $1.order ? $0.name < $1.name : $0.order < $1.order }
        
        for i in 0..<routine.exercises.count {
            let new = newExercises[i]
            let og = ogExercises[i]
            
            if new.name != og.name || new.reps != og.reps || new.weights != og.weights || new.seconds != og.seconds || new.restTime != og.restTime || new.repsColumn != og.repsColumn || new.weightColumn != og.weightColumn || new.secsColumn != og.secsColumn || new.order != og.order {
                return true
            }
        }
        
        return false
    }
    
    // one set per entry in reps, the same way ContinueWhereYouLeftOff counts them
    private var totalSetCount: Int {
        routine.exercises.reduce(0) { $0 + $1.reps.count }
    }

    private var completedSetCount: Int {
        routine.exercises.reduce(0) { $0 + $1.completedSets.count }
    }

    // stats
    @ViewBuilder
    private var statsSection: some View {

        HStack(spacing: 16) {
            Text("Stats")
                .font(.headline)

            Spacer()

            HStack(spacing: 4) {
                Text("Time:")

                // keeps counting while this screen is open, since the workout only really ends
                // once one of the buttons below is pressed and the duration is taken then
                WorkoutTimer()
            }

            Text("Sets: \(completedSetCount)/\(totalSetCount)")
        }
        .monospacedDigit()
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
    
    // the exercises that beat their stored best, gold so they read as the good news on the screen
    @ViewBuilder
    private var newPersonalBestsSection: some View {
        let personalBests = newPersonalBests

        if !personalBests.isEmpty {
            VStack(alignment: .leading) {
                Text(personalBests.count == 1 ? "New personal best" : "New personal bests")
                    .font(.headline)

                ForEach(personalBests) { personalBest in
                    HStack {
                        Text(personalBest.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(formattedWeight(personalBest.weight, unit: appSettings.weightUnit)) \(appSettings.weightUnit.label)")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()

                            Text(personalBest.previous > 0 ? "was \(formattedWeight(personalBest.previous, unit: appSettings.weightUnit)) \(appSettings.weightUnit.label)" : "first one logged")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(Theme.checkedSetGold)
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Date().formatted(.dateTime.month(.wide).year()))
                    .font(.headline)

                Spacer()

                Text("\(daysThisMonth) \(daysThisMonth == 1 ? "day" : "days") this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(Array(weekdayInitials.enumerated()), id: \.offset) { _, initial in
                    Text(initial)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        daySquare(date)
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding()
        .glassEffect(in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var routineChangesSection: some View {
        let changes = routineChanges

        return VStack(alignment: .leading, spacing: 10) {
            Text("Changes to this routine")
                .font(.headline)

            changeRow("Added", changes.added, Theme.primary)
            changeRow("Edited", changes.edited, Theme.primary)
            changeRow("Removed", changes.removed, Theme.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    // one row of exercise names, wrapping onto as many lines as it needs
    private func changeRow(_ label: String, _ names: [String], _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 70, alignment: .leading)

            Text(names.isEmpty ? "None" : names.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(names.isEmpty ? Color.secondary : Theme.oppositeBackground)
                // lets the names run onto more lines instead of being squeezed onto one
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // blue for a day with a workout on it, an empty outline for a day without one
    private func daySquare(_ date: Date) -> some View {
        let worked = loggedDays.contains(calendar.startOfDay(for: date))
//        let isToday = calendar.isDateInToday(date)

        return RoundedRectangle(cornerRadius: 8)
            .fill(worked ? Theme.primary : Color.clear)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.35))
            )
            .overlay(
                Text("\(calendar.component(.day, from: date))")
                    .font(.caption2)
                    .foregroundStyle(worked ? Color.white : Theme.oppositeBackground)
            )
    }

    private func MoveThisRoutineToTheEnd() {
        for r in routines {
            if r.order > routine.order {
                r.order -= 1
            }
        }
        
        routine.order = routines.count-1

    }

}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Routine.self, WorkoutHistoryEntry.self, WorkOutLongSave.self, configurations: config)

    // the same object is handed to both the session and the view, like ContentView does
    let routine = Routine(name: "Push Day", exercises: [
        Exercise(name: "Barbell Bench Press", reps: [8, 8, 6], seconds: [0, 0, 0], completedSets: [0, 1, 2], weights: [135, 155, 175], restTime: 90, order: 0),
        Exercise(name: "Incline Dumbbell Press", reps: [10, 10, 8], seconds: [0, 0, 0], completedSets: [0, 1], weights: [50, 55, 55], restTime: 90, order: 1),
        Exercise(name: "Cable Fly", reps: [12, 12, 12], seconds: [0, 0, 0], completedSets: [], weights: [30, 30, 35], restTime: 60, order: 2)
    ], order: 0)

    let _ = container.mainContext.insert(routine)

    let session = WorkoutSession()
    let _ = session.start(routine, container.mainContext, Date().addingTimeInterval(-2700), true, givenOriginalExercises: [], useGivenOriginalExercises: false)

    WorkoutEndSummaryView(routine: routine)
        .environment(session)
        .environment(AuthManager())
        .environment(AppSettings())
        .modelContainer(container)
}
