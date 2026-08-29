//
//  UploadRoutineToHistorySupabase.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-22.
//

import Foundation
import Supabase

// the struct used to upload a workout to the database
struct HistoryInsertDTO: Encodable {
    let user_id: UUID
    let name: String
    let exercises: [ExerciseDTO]
    let routine_id: UUID
    let duration_seconds: Int
}

func uploadRoutineToHistorySupabase(_ routine: Routine, routineId: UUID, duration: Int) async throws {
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

    let dto = HistoryInsertDTO(
        user_id: userId,
        name: routine.name,
        exercises: exerciseDTOs,
        routine_id: routineId,
        duration_seconds: duration
    )

    try await supabase
        .from("history")
        .insert(dto)
        .execute()
}
