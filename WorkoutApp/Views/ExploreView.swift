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
            
            Text("Find your friends and see their posts")
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
