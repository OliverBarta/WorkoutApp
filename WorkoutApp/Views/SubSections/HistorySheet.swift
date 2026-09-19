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

    // "day start" date → routine name of the workout logged that day, for fast lookup
    private var workoutDays: [Date: String] {
        history.reduce(into: [:]) { result, entry in
            result[calendar.startOfDay(for: entry.dateCompleted)] = entry.routineName
        }
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
                            let routineName = workoutDays[calendar.startOfDay(for: date)]

                            VStack {
                                Text("\(dayNumber)")
                                    .font(.caption)
                                    .frame(width: 40, height: 40)
                                    .background(routineName != nil ? Theme.primary : Color.clear)
                                    .clipShape(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 12,
                                            bottomLeadingRadius: 12,
                                            bottomTrailingRadius: 12,
                                            topTrailingRadius: 12
                                        )
                                    )

                                if let routineName {
                                    Text(routineName)
                                        .font(.system(size: 8))
                                        .lineLimit(1)
                                }
                            }

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
