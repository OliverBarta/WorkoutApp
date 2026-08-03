//
//  DeleteRoutine.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//

import Supabase

func deleteRoutineFromSupabase(_ routine: Routine) async throws {
    try await supabase
        .from("routines")
        .delete()
        .eq("id", value: routine.id)
        .execute()
}
