//
//  ProgressView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//

import SwiftUI

struct ProgressView: View {
    var body: some View {
        Image(systemName: "dumbbell")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
        Text("Loading...")
    }
}

#Preview {
    ProgressView()
}
