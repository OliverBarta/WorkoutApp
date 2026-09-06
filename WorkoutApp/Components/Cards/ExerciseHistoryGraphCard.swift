//
//  ExerciseWeightHistoryGraphCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-05.
//

import SwiftUI
import Charts

struct GraphDataPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let value: Double

    // has to be codable to be saved to userdefaults
    init(id: UUID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

struct ExerciseHistoryGraphCard: View {
    let dataPoints: [GraphDataPoint]
    
    var body: some View {
        VStack {
            if !dataPoints.isEmpty {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.value)
                    )
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 220)
            } else {
                Text("No history of this exercise")
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    
    let sampleData: [GraphDataPoint] = [
        GraphDataPoint(date: calendar.date(byAdding: .day, value: -28, to: today)!, value: 135),
        GraphDataPoint(date: calendar.date(byAdding: .day, value: -21, to: today)!, value: 140),
        GraphDataPoint(date: calendar.date(byAdding: .day, value: -14, to: today)!, value: 145),
        GraphDataPoint(date: calendar.date(byAdding: .day, value: -7, to: today)!, value: 145),
        GraphDataPoint(date: today, value: 155)
    ]
    
    return ExerciseHistoryGraphCard(dataPoints: sampleData)
        .padding()
}
