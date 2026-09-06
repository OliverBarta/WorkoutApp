//
//  UploadRoutineToHistorySupabase.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-22.
//

import Foundation
import Supabase

// the struct used to upload a workout to the database. RoutineHistory is a @Model class and so
// cannot be Encodable, which is why the row is built out of plain structs here instead.
// id and updated_at are filled in by supabase, so they are not sent
struct HistoryInsertDTO: Encodable {
    let user_id: UUID
    let name: String
    let exercises: [ExerciseHistoryDTO]
    let routine_id: UUID
    let duration_seconds: Int
}

struct PBToUpload {
    var userId: UUID
    var exerciseName: String
    var weight: Double
}

// uploads the routine to history and updates/uploads the new pbs and updates volumeHistory and weightHistory
func uploadRoutineToHistorySupabase(_ routine: Routine, routineId: UUID, duration: Int, appSettings: AppSettings) async throws {
    guard let userId = supabase.auth.currentSession?.user.id else {
        throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
    }
    
    var pbsToUpload: [PBToUpload] = []

    let exerciseDTOs = routine.exercises.compactMap { exercise -> ExerciseHistoryDTO? in
        var reps: [Int] = []
        var weights: [Double] = []
        var seconds: [Int] = []

        var PB = (appSettings.personalBests[exercise.name] ?? 0)
        var PBIndex: Int = -1
        var PBFound = false

        var totalWeight: Double = 0
        var totalSets: Double = 0
        
        for setIndex in exercise.completedSets {
            if PB < exercise.weights[setIndex] {
                PB = exercise.weights[setIndex]
                PBIndex = reps.count
                PBFound = true
            }
            
            totalSets += Double(exercise.reps[setIndex])
            totalWeight += exercise.weights[setIndex]

            reps.append(exercise.reps[setIndex])
            weights.append(exercise.weights[setIndex])
            seconds.append(exercise.seconds[setIndex])
        }
        
        if exercise.completedSets.count > 0 {
            // saving to weightHistory for the graph
            var weightHistory = appSettings.weightHistory[exercise.name] ?? []
            
            totalWeight = totalWeight/Double(exercise.completedSets.count) // average weight of the set
            
            let newWeightDataPoint = GraphDataPoint(
                date: Date(),
                value: totalWeight
            )
            
            weightHistory.append(newWeightDataPoint)// save to weight history
            appSettings.weightHistory[exercise.name] = weightHistory
            //
            
            // saving to volumeHistory for the volume graph
            var volumeHistory = appSettings.volumeHistory[exercise.name] ?? []
            
            let newVolumeDataPoint = GraphDataPoint(
                date: Date(),
                value: totalSets
            )
            
            volumeHistory.append(newVolumeDataPoint)
            appSettings.volumeHistory[exercise.name] = volumeHistory
            //
            
            // saving this exercise setup
            appSettings.exerciseSetup[exercise.name] = ExerciseSetup(
                reps: reps, weights: weights, seconds: seconds, restTime: exercise.restTime, repsColumn: exercise.repsColumn, weightColumn: exercise.weightColumn, secsColumn: exercise.secsColumn)
            //
        }
        
        if PBFound {
            appSettings.personalBests[exercise.name] = PB // local save
            
            pbsToUpload.append(
                PBToUpload(
                    userId: userId,
                    exerciseName: exercise.name,
                    weight: PB
                )
            )
        }

        // an exercise nobody completed a set of is left out of the upload entirely
        guard !reps.isEmpty else { return nil }

        return ExerciseHistoryDTO(
            name: exercise.name,
            reps: reps,
            weights: weights,
            seconds: seconds,
            restTime: exercise.restTime,
            repsColumn: exercise.repsColumn,
            weightColumn: exercise.weightColumn,
            secsColumn: exercise.secsColumn,
            order: exercise.order,
            personalBestIndex: PBIndex
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
    
    // goes through the pbs and uploads them
    for upload in pbsToUpload {
        try await uploadPBToSupabase(userId: upload.userId, exerciseName: upload.exerciseName, weight: upload.weight) // database save
    }
}
