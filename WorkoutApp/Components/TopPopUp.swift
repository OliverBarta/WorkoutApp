//
//  TopPopUp.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-07.
//

import SwiftUI

// pops up if the message passed into it is anything but "" then after 3 seconds sets that variable passed into it by reference to ""
struct TopPopUp: View {
    @Binding var message: String
    
    var body: some View {
        VStack {
            if message != "" {
                HStack(spacing: 12) {
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                }
                .padding()
                .padding(.horizontal)
                .glassEffect(in: Capsule())
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.spring()) {
                            message = ""
                        }
                    }
                }
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
    }
}

// Example
struct ExampleView: View {
    @State private var message = ""

    var body: some View {
        ZStack {
            VStack {
                Button("Show Pop-up") {
                    withAnimation {
                        message = "test"
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(
            TopPopUp(message: $message)
        )
    }
}

#Preview {
    ExampleView()
}
