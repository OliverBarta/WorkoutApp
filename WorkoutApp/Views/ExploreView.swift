//
//  ExplorView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-30.
//

import SwiftUI

struct ExploreView: View {
    var body: some View {
        ScrollView {
            Rectangle()
                .padding(.top, 35)
                .opacity(0)
            
            Text("Explore")
        }
        .frame(maxWidth: .infinity)
        .overlay {
            VStack {
                ZStack {
                    
                    Text("Explore")
                        .headerStyle()
                }
                Spacer()
                
            }
        }
    }
}

#Preview {
    ExploreView()
}
