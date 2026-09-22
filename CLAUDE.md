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

- **`WorkoutSession`** — the live workout. **`workoutRoutine` is the live SwiftData `Routine`, not a copy** — ticking a set or editing a weight during a workout mutates the stored routine in place. That is what makes crash recovery work (see `WorkOutLongSave`), and it is why `originalRoutineExercises: [Exercise]` holds detached copies of the pre-workout exercises: *every* exit path that isn't "Log and update" must restore with `routine.exercises = workoutSession.originalRoutineExercises.map { $0.copy() }` before calling `end(_:)`. `start(_:_:_:_:givenOriginalExercises:useGivenOriginalExercises:)` takes the `ModelContext` so it can replace the `WorkOutLongSave` row and `save()` immediately; the two `given…` parameters are only used by the crash-recovery path, which must carry the *pre-crash* originals through rather than re-deriving them from the already-mutated routine. `workoutStartDate` and `restTimerStartDate` are stored as `Date` (plus `exerciseBeingTimed`) so timers keep running while the view is off screen. `newPersonalBest` is set by `ExerciseDuringWorkoutCard` when a completed set beats the record and cleared when the celebration is dismissed. `end(_:)` deletes the `WorkOutLongSave` rows and clears everything.
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

`Routine` → `[Exercise]` and `WorkoutHistoryEntry` → `[ExerciseSnapshot]`, each with a cascade delete relationship. Views read routines with `@Query(sort: \Routine.order)` rather than passing them down.

**`Routine.order` is maintained by hand as a contiguous `0..<n`,** and every site that changes membership has to renumber the whole list itself: `RoutineSelectorView` inserts a new routine at `order: 0` and bumps every other `+1` (so does `RoutineSpectateView` when copying someone else's), `RoutineCard`'s delete decrements everything after the deleted one, and `RoutineDuringWorkoutView.MoveThisRoutineToTheEnd()` sends a just-logged routine to `routines.count - 1`. The arithmetic assumes contiguity — adding a path that leaves a gap or a tie silently corrupts the ordering everywhere.

**`Exercise` uses parallel arrays** — `reps: [Int]`, `weights: [Double]`, `seconds: [Int]`, one entry per set, plus `completedSets: Set<Int>` of indices. Always add and remove sets through `addSet()` / `removeSet(at:)` (Routine.swift) so the three arrays stay the same length and `completedSets` indices are reindexed. Exercise order is an explicit `order: Int`, so views sort with `routine.exercises.sorted { $0.order < $1.order }`.

`copy()` vs `copyCompletedSetsToZero()` matters: the first is for starting a session, the second for writing the session back to the stored routine without carrying completion state.

`ReorderExercisesView` (`Views/SubSections/`) is the shared sheet for both reordering **and** deleting exercises — `RoutineEditView` and `RoutineDuringWorkoutView` each open it from the `arrow.up.arrow.down` button, and both its `move` and `remove` handlers renumber `order` over the whole list afterwards.

`WorkOutLongSave` (`WorkOutLongSave.swift`) is the crash-recovery row — `startDate` + `routine` (a reference to the *live* routine) + `originalExercises` (cascade-owned copies of how that routine looked before the workout). There is at most one: `WorkoutSession.start` deletes any stale rows, inserts a fresh one and `save()`s explicitly. Because the workout mutates the live routine, a crash leaves the in-progress state already on disk; the row just records that a workout was open and what to roll back to.

`ContentView` reads it with an unsorted `@Query` and presents `ContinueWhereYouLeftOff` (`Views/SubSections/`) in a `fullScreenCover` from `.task` when one exists. "Continue" calls `start(…, useGivenOriginalExercises: true)` with `leftOff.originalExercises` so the pre-crash originals survive; "Don't Continue" restores the routine from them and deletes the row.

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

`RoutineDuringWorkoutView` shows a sheet with four choices — "Log and update", "Log, don't update", "Don't log or update", cancel. The two logging paths run the same sequence inline in the button action:

1. Capture `duration` from `workoutSession.workoutStartDate` and take `historySnapshot = history` — a snapshot of the `@Query` results taken *before* step 2, since it would otherwise already include the new entry.
2. `saveRoutineToHistory(workoutRoutine, duration, modelContext, appSettings.personalBests)` — inserts a `WorkoutHistoryEntry` locally, keeping only completed sets, and records `personalBestIndex` per exercise.
3. One `Task` for the uploads: ("Log and update" only) `uploadRoutineToSupabase(routine)`, then `uploadRoutineToHistorySupabase(workoutRoutine, routineId:duration:appSettings:)` — inserts the `history` row **and** does all the `AppSettings` bookkeeping: PBs (compared against `appSettings.personalBests`, written back, then upserted via `uploadPBToSupabase`), a `weightHistory` point (mean weight across completed sets), a `volumeHistory` point, and the `exerciseSetup` entry. Sharing one `Task` means a failed routine upload skips the history upload.
4. `authManager.updateStreakAfterWorkout(history: historySnapshot)` in a separate `Task`.
5. The routine's exercises are rewritten synchronously — `copyCompletedSetsToZero()` for "Log and update", `originalRoutineExercises` for "Log, don't update" — then `MoveThisRoutineToTheEnd()`, `workoutSession.end(modelContext)` and `dismiss()`.

**Step 5 runs before the `Task`s in steps 3–4 ever start.** A `Task {}` created in a `@MainActor` button action is only *enqueued*; nothing in it executes until the action returns. So `uploadRoutineToHistorySupabase` reads the exercises *after* they have been zeroed or reset — see Gotchas. Anything that needs the as-completed sets has to snapshot them synchronously before step 5, not rely on statement order.

**`appSettings.personalBests` is only updated in step 3**, after the local history entry is written. That ordering is deliberate (step 2 needs the pre-workout bests to mark `personalBestIndex`) but it is also why the live in-workout celebration can fire more than once for the same exercise.

The discard paths — "Don't log or update", the "End workout without logging" sheet, and the End button on `CurrentActivityIndicatorCard` — each restore `originalRoutineExercises` before `end(modelContext)`. A new exit path that forgets this leaves the stored routine permanently carrying the workout's completed sets and edits.

## Conventions

- **Exercise names are case-sensitive dictionary keys, except for PBs.** `personalBests` and the remote `personalbest.exercise` column are keyed lowercased — `uploadPBToSupabase` lowercases on write and `pullGlobalTop` / `pullFollowingTop` lowercase the query — while `weightHistory`, `volumeHistory` and `exerciseSetup` use `exercise.name` verbatim. Match the surrounding site when adding a lookup.
- **Weights are always stored in pounds.** Convert only at the UI edge, via `appSettings.weightBinding(_:)` for input boxes and `formattedWeight(_:unit:)` / `formattedSet(...)` for display (`Components/Formatting.swift`). Routines are shared between users, so a stored number must mean the same thing regardless of either user's `weightUnit`.
- Styling constants live in `Theme.swift` (colors, `padding`, `cornerRadius`). The app leans on iOS 26 Liquid Glass — `.buttonStyle(.glassProminent)` and `.glassEffect(in:)` — and on the `.headerStyle()` modifier (`Components/HeaderStyle.swift`) for the floating title capsule.
- Screens that use `.headerStyle()` in an `.overlay` open their `ScrollView` with an invisible `Rectangle().padding(.top, 35).opacity(0)` spacer so content clears the floating header. The modifier clamps to `.lineLimit(1)`, and each call site adds its own `.padding(.horizontal, N)` sized to the buttons flanking it in that `ZStack`, so a long routine or user name truncates instead of sliding under them.
- Views with text fields hold a `@State private var keyboardObserver = KeyboardObserver()` (`Models/KeyboardObserver.swift`, a `@Observable` wrapper over the keyboard notifications) and hang a dismiss button off `.safeAreaInset(edge: .bottom)` while `keyboardObserver.isVisible`. It is per-view state, not an environment object.
- Sheets use `.presentationCornerRadius(12)`.
- A disabled glass button dims itself — `.disabled(cond)` alongside `.foregroundColor(cond ? Color.secondary.opacity(0.5) : Theme.oppositeBackground)` — since `.buttonStyle(.glass)` does not grey out on its own.
- Async errors are handled by `print(...)` plus assigning to a local `@State private var errorMessage: String` — follow the surrounding pattern rather than introducing a new error type. The same `errorMessage` doubles as the transient-toast channel: views overlay `TopPopUp(message: $errorMessage)` (`Components/TopPopUp.swift`), which shows any non-empty string and clears the binding after 3 seconds, so it is also how non-error notices ("Cannot edit active workouts", "All rest times set to …") get shown.
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
- **The end-of-workout uploads read the routine after it has been rewritten.** Because `workoutRoutine` is now the live routine and step 5 above is synchronous, `uploadRoutineToHistorySupabase` sees `completedSets` that are already empty (zeroed for "Log and update", reset to the originals for "Log, don't update"). In practice every logged workout uploads a `history` row with `exercises: []` and skips the PB / `weightHistory` / `volumeHistory` / `exerciseSetup` bookkeeping. The local `WorkoutHistoryEntry` is unaffected — it is written synchronously in step 2. Moving the rewrite below the `Task {}` block does **not** fix this.
- `WorkOutLongSave.originalExercises` declares `@Relationship(deleteRule: .cascade, inverse: \Exercise.routine)`, but `Exercise.routine` is a `Routine?` and is already the inverse of `Routine.exercises`. It compiles (`inverse:` takes `AnyKeyPath?`) and the container still builds at launch, so SwiftData is either ignoring the argument or mis-wiring the graph. Only the `.cascade` rule is wanted here.
- `WorkoutSession.start` calls `context.save()` but `end(_:)` does not, so the `WorkOutLongSave` delete can still be unflushed if the app dies right after a workout is logged — the next launch then offers to resume a workout that is already in history.
- Nothing saves the context while a workout is running; mid-workout progress reaches disk only via SwiftData autosave, so a hard crash can lose the last few ticked sets.
- `WorkOutLongSave.routine` is non-optional and `RoutineCard`'s delete button is not gated on `workoutSession.isActive` (Start and Edit are), so deleting the routine you are currently working out leaves both that row and `workoutSession.workoutRoutine` pointing at a deleted model.
- `Routine.order` was added without a default, so routines that predate it all migrate to `0` and the hand-maintained ordering is arbitrary until each one is touched.
- `AppSettings.routineCycle` is stored and loaded but unused, as its comments say.
