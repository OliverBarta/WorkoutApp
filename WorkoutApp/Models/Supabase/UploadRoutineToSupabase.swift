//
//  UploadRoutineToSupabase.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//


import Foundation
import Supabase

// uploads a routine to supabase, if that routine already exists it updates it
func uploadRoutineToSupabase(_ routine: Routine) async throws {
    guard let userId = supabase.auth.currentSession?.user.id else {
        throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
    }

    let exerciseDTOs = routine.exercises.map {
        ExerciseDTO(
            name: $0.name,
            reps: $0.reps,
            weights: $0.weights,
            seconds: $0.seconds,
            restTime: $0.restTime,
            repsColumn: $0.repsColumn,
            weightColumn: $0.weightColumn,
            secsColumn: $0.secsColumn,
            order: $0.order
        )
    }

    let dto = RoutineDTO(
        id: routine.id,
        user_id: userId,
        name: routine.name,
        exercises: exerciseDTOs
    )

    try await supabase
        .from("routines")
        .upsert(dto)
        .execute()
}

// same as above function but generates a new routine ID and returns the new routine
// useful when a user is copying someone else's routine
func copyRoutineToSupabase(_ routine: Routine) async throws -> Routine {
    guard let userId = supabase.auth.currentSession?.user.id else {
        throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
    }

    let exerciseDTOs = routine.exercises.map {
        ExerciseDTO(
            name: $0.name,
            reps: $0.reps,
            weights: $0.weights,
            seconds: $0.seconds,
            restTime: $0.restTime,
            repsColumn: $0.repsColumn,
            weightColumn: $0.weightColumn,
            secsColumn: $0.secsColumn,
            order: $0.order
        )
    }

    let newId = UUID()

    let dto = RoutineDTO(
        id: newId,
        user_id: userId,
        name: routine.name,
        exercises: exerciseDTOs
    )

    try await supabase
        .from("routines")
        .upsert(dto)
        .execute()

    let newRoutine = Routine(id: newId, name: routine.name)
    newRoutine.exercises = routine.exercises.map {
        Exercise(
            name: $0.name,
            reps: $0.reps,
            seconds: $0.seconds,
            completedSets: [],
            weights: $0.weights,
            restTime: $0.restTime,
            repsColumn: $0.repsColumn,
            weightColumn: $0.weightColumn,
            secsColumn: $0.secsColumn,
            order: $0.order
        )
    }

    return newRoutine
}
