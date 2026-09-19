# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`WorkoutApp` — a SwiftUI/SwiftData iOS app for building workout routines, running a live workout, and sharing results in a social feed. Single Xcode target, no test target. iOS deployment target 26.2, `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad). Dependency: `supabase-swift` via SPM (Auth, Functions, PostgREST, Realtime, Storage).

## Commands

```bash
# Build
xcodebuild -project WorkoutApp.xcodeproj -scheme WorkoutApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build + run in the simulator
xcodebuild -project WorkoutApp.xcodeproj -scheme WorkoutApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd build
xcrun simctl boot "iPhone 17"; open -a Simulator
xcrun simctl install booted /tmp/dd/Build/Products/Debug-iphonesimulator/WorkoutApp.app
xcrun simctl launch booted com.oliver.WorkoutApp
```

There are no tests and no linter configured. Most views carry a `#Preview` — previews are the normal way to check a UI change.

The target uses `fileSystemSynchronizedGroups`, so a new `.swift` or resource file dropped anywhere under `WorkoutApp/` joins the target automatically — never hand-edit `project.pbxproj` to add one.

## Architecture

### State: three `@Observable` objects injected at the app root

`WorkoutAppApp.swift` creates and injects `WorkoutSession`, `AuthManager`, and `AppSettings` into the environment, and installs the SwiftData container for `[Routine.self, WorkoutHistoryEntry.self, WorkOutLongSave.self]`. It gates on `authManager.isLoading` / `isSignedIn` to pick between `LoadingStartView`, `SignInView`, and `ContentView`. Views reach these with `@Environment(WorkoutSession.self)` etc.

- **`WorkoutSession`** — the live workout. Holds `workoutRoutine` (a *copy* being edited during the session) alongside `originalRoutine` (the SwiftData object). `start(_:)` sets both; the "Log and update" path at the end writes the copy's exercises back onto the original. `workoutStartDate` and `restTimerStartDate` are stored as `Date` (plus `exerciseBeingTimed`) so timers keep running while the view is off screen. `newPersonalBest` is set by `ExerciseDuringWorkoutCard` when a completed set beats the record and cleared when the celebration is dismissed. `end()` clears everything.
- **`AuthManager`** — Supabase session, `currentUserId`, `currentUsername`, `currentStreak`. The streak is weekly: unchanged if a workout was already logged this week, +1 if last week had one, otherwise reset to 1.
- **`AppSettings`** — device-local preferences persisted to `UserDefaults` via `didSet` on each property, and read back in `init()`. Simple values go in with `UserDefaults.standard.set`; the dictionary-valued ones (`weightHistory`, `volumeHistory`, `exerciseSetup`) are JSON-encoded first. Beyond preferences it owns four derived stores that no other layer holds — see below. Note not every property is exposed in `SettingsMenu`: `showPreviousExercises` is toggled from `ExerciseSearchView`'s "Hide/Show" button, and the leaderboard ones from the leaderboard cards.

`ContentView` is a 4-tab `TabView` (Home / Routines / Running / Explore) with `CurrentActivityIndicatorCard` overlaid when a workout is active, and a `fullScreenCover` for `RoutineDuringWorkoutView`.

### `AppSettings` as a data store, not just settings

Four properties on `AppSettings` are the *only* store for their data — they are written during the end-of-workout upload (step 4 below) and read by the UI. None of them are pulled back from Supabase, so a reinstall loses all of it.

- `personalBests: [String: Double]` — exercise name → best weight in pounds. The only store the PB logic reads. **Keyed by `exercise.name.lowercased()`** at every read and write site, to match the remote `personalbest.exercise` column (see Conventions).
- `weightHistory` / `volumeHistory: [String: [GraphDataPoint]]` — one point appended per exercise per logged workout, rendered by `ExerciseHistoryGraphCard` in `ExerciseClickedView`. `GraphDataPoint` is defined in `ExerciseHistoryGraphCard.swift`.
- `exerciseSetup: [String: ExerciseSetup]` — the last-used column layout, reps/weights/seconds and rest time for each exercise. It does double duty: it seeds a newly added exercise (`RoutineEditView`, `RoutineDuringWorkoutView`, `ExerciseSearchView`) and its keys are the "exercises you have done" list `ExerciseSearchView` shows before you type. The `lastRestTime` toggle picks whether a new exercise takes `setup?.restTime` or `defaultRestSeconds`.

`homeLeaderBoardExerciseName`, `homeLeaderBoardMode` and `exerciseLeaderBoardMode` persist leaderboard state so the user's choice survives a relaunch.

### Local persistence: SwiftData

`Routine` → `[Exercise]` and `WorkoutHistoryEntry` → `[ExerciseSnapshot]`, each with a cascade delete relationship. Views read routines with `@Query(sort: \Routine.name)` rather than passing them down.

**`Exercise` uses parallel arrays** — `reps: [Int]`, `weights: [Double]`, `seconds: [Int]`, one entry per set, plus `completedSets: Set<Int>` of indices. Always add and remove sets through `addSet()` / `removeSet(at:)` (Routine.swift) so the three arrays stay the same length and `completedSets` indices are reindexed. Exercise order is an explicit `order: Int`, so views sort with `routine.exercises.sorted { $0.order < $1.order }`.

`copy()` vs `copyCompletedSetsToZero()` matters: the first is for starting a session, the second for writing the session back to the stored routine without carrying completion state.

`ReorderExercisesView` (`Views/SubSections/`) is the shared sheet for both reordering **and** deleting exercises — `RoutineEditView` and `RoutineDuringWorkoutView` each open it from the `arrow.up.arrow.down` button, and both its `move` and `remove` handlers renumber `order` over the whole list afterwards.

`WorkOutLongSave` (`WorkOutLongSave.swift`) is a `@Model` in the container — `startDate` + `routine` + `routineSaved` — meant to persist an in-progress workout so a crash doesn't lose it. **Nothing reads or writes it yet**; the crash-recovery path is unbuilt, so `WorkoutSession` is still the only live-workout state.

`RoutineHistory` / `ExerciseHistory` (`RoutineHistory.swift`) are also `@Model` classes but are **deliberately not in the model container** — they are never inserted, only built in memory by `exercisesToRoutineHistory(_:name:)` to hand a decoded remote `HistoryRow` to `ExploreFeedCard`. `routineHistoryToRoutine` turns one back into a `Routine` so a logged workout can be re-run or copied. The local equivalent is `workoutHistoryToRoutine(_:_:)` (`WorkoutHistory.swift`), which takes `AppSettings` so the rebuilt exercises get `defaultRestSeconds`.

### Remote persistence: Supabase

`Models/Supabase/SupabaseClient.swift` declares a **global `let supabase`** client with the project URL and anon key inline; every network function is a free function that uses it directly. There is no repository/service layer — functions are grouped by verb:

- `PullingFunctions.swift` — profiles, follower/following counts, routines, feed (`pullFeed` following-only and `pullFeedGlobal`, both cursor-paginated on `updated_at` via a `before:` parameter), likes, comments, streaks, `pullPersonalBests`.
- `PushingFunctions.swift` — `postComment`, `uploadPBToSupabase` (personal-best upsert).
- `leaderBoards.swift` — `pullGlobalTop` and `pullFollowingTop`, both `(exerciseName:startLoad:endLoad:)` over the `personalbest` table ordered by weight, paged with `.range(from:to:)`, then resolving each `user_id` to a username with a **`pullUsername` call per row** (N+1). Two cards consume them: `LeaderBoardCardHome` (Home tab, exercise name and mode come from `AppSettings`, editable inline) and `LeaderBoardCard` (takes an `exerciseName` and a `cardMode` binding; used by `ExerciseClickedView`).
- `UploadRoutineToSupabase.swift` (`uploadRoutineToSupabase` upserts in place; `copyRoutineToSupabase` mints a new UUID for copying someone else's routine), `UploadRoutineToHistorySupabase.swift`, `DeleteRoutineFromSupabase.swift`, `FollowingFunctions.swift`, `AuthManager.swift`.

Tables in use: `profiles`, `routines`, `history`, `follows`, `likes`, `comments`, `streaks`, `personalbest`.

**SwiftData is the source of truth for the signed-in user's own routines and history; Supabase is a mirror for sharing.** Writes go local first, then fire a `Task` to push. There is no sync-back or reconciliation — a failed upload is only surfaced as an `errorMessage` string.

### DTO boundary

`RoutineDTO` / `ExerciseDTO` / `ExerciseHistoryDTO` (`RoutineDTO.swift`) are `Codable` mirrors of the `@Model` classes; the `exercises` column is a JSON array in one cell. Supabase-facing structs use `snake_case` property names to match column names directly (`user_id`, `history_item_id`, `routine_id`) instead of `CodingKeys`. `toModel()` converts back and always resets `completedSets` to empty.

Note `HistoryRow.routine_id` is optional — deleting a routine nulls it on the history rows that referenced it.

### End-of-workout flow

`RoutineDuringWorkoutView` shows a sheet with three choices ("Log and update", "Log", cancel/discard). Both logging paths run the same sequence inline in the button action:

1. Capture `duration` from `workoutSession.workoutStartDate` and take `historySnapshot = history` — a snapshot of the `@Query` results taken *before* step 2, since it would otherwise already include the new entry.
2. `saveRoutineToHistory(workoutRoutine, duration, modelContext, appSettings.personalBests)` — inserts a `WorkoutHistoryEntry` locally, keeping only completed sets, and records `personalBestIndex` per exercise.
3. ("Log and update" only) `routine.exercises = workoutRoutine.exercises.map { $0.copyCompletedSetsToZero() }`, then `uploadRoutineToSupabase(routine)`.
4. `uploadRoutineToHistorySupabase(workoutRoutine, routineId:duration:appSettings:)` — inserts the `history` row **and** does all the `AppSettings` bookkeeping: PBs (compared against `appSettings.personalBests`, written back, then upserted via `uploadPBToSupabase`), a `weightHistory` point (mean weight across completed sets), a `volumeHistory` point, and the `exerciseSetup` entry. Steps 3 and 4 share one `Task`, so a failed routine upload skips the history upload.
5. `authManager.updateStreakAfterWorkout(history: historySnapshot)` in a separate `Task`.
6. `workoutSession.end()` and `dismiss()` — these run synchronously, before the `Task`s above finish.

**`appSettings.personalBests` is only updated in step 4**, after the local history entry is written. That ordering is deliberate (step 2 needs the pre-workout bests to mark `personalBestIndex`) but it is also why the live in-workout celebration can fire more than once for the same exercise.

## Conventions

- **Exercise names are case-sensitive dictionary keys, except for PBs.** `personalBests` and the remote `personalbest.exercise` column are keyed lowercased — `uploadPBToSupabase` lowercases on write and `pullGlobalTop` / `pullFollowingTop` lowercase the query — while `weightHistory`, `volumeHistory` and `exerciseSetup` use `exercise.name` verbatim. Match the surrounding site when adding a lookup.
- **Weights are always stored in pounds.** Convert only at the UI edge, via `appSettings.weightBinding(_:)` for input boxes and `formattedWeight(_:unit:)` / `formattedSet(...)` for display (`Components/Formatting.swift`). Routines are shared between users, so a stored number must mean the same thing regardless of either user's `weightUnit`.
- Styling constants live in `Theme.swift` (colors, `padding`, `cornerRadius`). The app leans on iOS 26 Liquid Glass — `.buttonStyle(.glassProminent)` and `.glassEffect(in:)` — and on the `.headerStyle()` modifier (`Components/HeaderStyle.swift`) for the floating title capsule.
- Screens that use `.headerStyle()` in an `.overlay` open their `ScrollView` with an invisible `Rectangle().padding(.top, 35).opacity(0)` spacer so content clears the floating header. The modifier clamps to `.lineLimit(1)`, and each call site adds its own `.padding(.horizontal, N)` sized to the buttons flanking it in that `ZStack`, so a long routine or user name truncates instead of sliding under them.
- Views with text fields hold a `@State private var keyboardObserver = KeyboardObserver()` (`Models/KeyboardObserver.swift`, a `@Observable` wrapper over the keyboard notifications) and hang a dismiss button off `.safeAreaInset(edge: .bottom)` while `keyboardObserver.isVisible`. It is per-view state, not an environment object.
- Sheets use `.presentationCornerRadius(12)`.
- A disabled glass button dims itself — `.disabled(cond)` alongside `.foregroundColor(cond ? Color.secondary.opacity(0.5) : Theme.oppositeBackground)` — since `.buttonStyle(.glass)` does not grey out on its own.
- Async errors are handled by `print(...)` plus assigning to a local `@State private var errorMessage: String` — follow the surrounding pattern rather than introducing a new error type.
- `ExerciseCatalog.all` lazily decodes **`exercises-3.json`** (bundled) into `ExerciseTemplate`, and derives `byId`, `sortedByName`, `muscleGroups` and `exercises(forMuscle:)` from it. `ExerciseSearchView` searches it alongside the user's own `appSettings.exerciseSetup` keys. The superseded `exercises-2.json` is still in the folder (and therefore still in the bundle) but nothing loads it.
- `pullProfilesFromSupabase` has a hardcoded fallback user id guarded by `XCODE_RUNNING_FOR_PREVIEWS` so the Explore search renders in previews.

## Gotchas

- **`personalBestIndex` means two different things.** `saveRoutineToHistory` sets it to `completedSetIndex` — an index into the *original* `exercise.weights` array — while the snapshot's own arrays are compacted to completed sets only. `uploadRoutineToHistorySupabase` sets it to `reps.count`, an index into the compacted array. The Supabase one is the correct convention; the local one is off whenever any earlier set was skipped.
- `uploadRoutineToHistorySupabase` iterates `exercise.completedSets` **unsorted** (a `Set<Int>`), so the reps/weights/seconds it uploads — and the `exerciseSetup` it saves — can be in arbitrary set order. `saveRoutineToHistory` sorts.
- `exerciseSetup` stores only the *completed* sets of the last workout, so an exercise where sets were skipped comes back shorter next time it is added.
- In `uploadRoutineToHistorySupabase` the local `totalSets` accumulates reps, not sets, and becomes the `volumeHistory` value — so "volume" is total reps, not reps × weight. `weightHistory` is the mean weight per completed set.
- `pullFollowingTop` pages the **global** ordered list with `.range(from:to:)` and only then filters by `following`, so a page of N rows usually comes back with far fewer than N and the "load more" paging stalls once the global head is exhausted.
- `AuthManager.personalBests` and `pullPersonalBests` both exist but are never used — PBs live entirely in `AppSettings` locally and in the `personalbest` table remotely, with no pull-on-launch. Reinstalling the app loses local PB state, and the graph and `exerciseSetup` stores with it.
- Lowercasing the `personalBests` keys was a change to existing behaviour: PBs written before it are still stored under their original casing in `UserDefaults` and are never read again, so an existing install looks like it lost its bests. There is no migration.
- `HomeView.computeWorkoutDays()` runs on `.onAppear` only and clears `workoutDays` but not `daysWithWorkout`, so that array accumulates across appearances and a day never loses its marker within a session.
- Known issue noted in `WorkoutSession`: a routine containing the same exercise twice celebrates its PB twice.
