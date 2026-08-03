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
            restTime: $0.restTime,
            type: $0.type,
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
