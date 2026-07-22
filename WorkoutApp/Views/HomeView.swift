//
//  HomeView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            ScrollView {
                Text("See you and the people you follow's workout and run history here. Coming soon.")
                    .padding(.top, 45)
                    .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .overlay {
                VStack {
                    Text("Home")
                        .headerStyle()
                    
                    Spacer()
                }
            }
            
        }
    }
}

#Preview {
    HomeView()
}
