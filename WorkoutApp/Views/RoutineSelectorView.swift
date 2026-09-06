//
//  HomeView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct RoutineSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Environment(AppSettings.self) private var appSettings
    
    // query makes routines the same everywhere so just type this and the variable is the same
    // sorted by name so the cards are always in the same order, an unsorted query gives no order guarantee
    @Query(sort: \Routine.name) private var routines: [Routine]

    // the spring used when a routine card is added or removed
    private static let cardAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.8)
    
    @State private var keyboardObserver = KeyboardObserver()

    var body: some View {
        NavigationStack {
            ScrollView {
                Rectangle()
                    .padding(.top, 35)
                    .opacity(0)

                Button {
                    let newRoutine = Routine(name: "Routine \(appSettings.routineNumber)")
                    
                    appSettings.routineNumber += 1
                    
                    withAnimation(Self.cardAnimation) {
                        modelContext.insert(newRoutine)
                    }
                } label : {
                    HStack {
                        Text("Routine")
                        Image(systemName: "plus")
                    }
                }
                .buttonStyle(.glassProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                VStack(spacing: 8) {
                    if routines.isEmpty {
                        Text("No routines yet, create one by tapping the blue button above or by going to someones profile in Explore and copying one of their routines.")
                            .foregroundColor(.secondary)
                            .padding(.top, 60)
                            .padding(.horizontal)
                            .transition(.opacity)
                    } else {
                        ForEach(routines) { routine in
                            RoutineCard(routine: routine, deletableCard: true)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                // animates cards sliding in when added and out when deleted from RoutineCard
                .animation(Self.cardAnimation, value: routines.count)

            }
            .scrollIndicators(.hidden)// hides the side scroll bar
            .frame(maxWidth: .infinity)
            .overlay {
                VStack {
                    Text("Routines")
                        .headerStyle()
                    Spacer()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if keyboardObserver.isVisible {
                    HStack {
                        Spacer()
                        Button {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .fontWeight(.semibold)
                                .padding()
                                .glassEffect()
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

#Preview {
    RoutineSelectorView()
        .modelContainer(for: Routine.self, inMemory: true)
        .environment(WorkoutSession())
}
