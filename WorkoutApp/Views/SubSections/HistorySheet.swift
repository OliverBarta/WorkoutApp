//
//  HistorySheet.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct HistorySheet: View {
    @Query(sort: \WorkoutHistoryEntry.dateCompleted) private var history: [WorkoutHistoryEntry]
    @State private var displayedMonth = Date()

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let calendar = Calendar.current

    // Set of "day start" dates that have a completed workout, for fast lookup
    private var workoutDays: Set<Date> {
        Set(history.map { calendar.startOfDay(for: $0.dateCompleted) })
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        let leadingEmptyDays = firstWeekday - 1 // 1 = Sunday
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        return days
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)

                    Spacer()

                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date {
                            let dayNumber = calendar.component(.day, from: date)
                            let hasWorkout = workoutDays.contains(calendar.startOfDay(for: date))

                            Text("\(dayNumber)")
                                .font(.caption)
                                .frame(width: 40, height: 40)
                                .background(hasWorkout ? Color.blue : Color.clear)
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 12,
                                        bottomLeadingRadius: 12,
                                        bottomTrailingRadius: 12,
                                        topTrailingRadius: 12
                                    )
                                )
                                
                        } else {
                            Color.clear
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 60)
        }
        .scrollIndicators(.hidden)// hides the side scroll bar
    }
}

#Preview {
    HistorySheet()
}
