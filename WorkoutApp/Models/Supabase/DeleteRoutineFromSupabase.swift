//
//  DeleteRoutine.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//

import Supabase

// this function deletes a given routine from supabase
func deleteRoutineFromSupabase(_ routine: Routine) async throws {
    try await supabase
        .from("routines")
        .delete()
        .eq("id", value: routine.id)
        .execute()
}
