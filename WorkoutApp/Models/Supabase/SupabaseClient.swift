//
//  SupabaseClient.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//
import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://oyesmmoouctaguunkuoy.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im95ZXNtbW9vdWN0YWd1dW5rdW95Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyMDQwMDQsImV4cCI6MjEwMDc4MDAwNH0.255Z7wi1XYbcqWzYtFjznfl-JagvuL7VcMa1bvvpqK8"
)
