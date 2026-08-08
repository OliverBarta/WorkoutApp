//
//  SearchBar.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-06.
//

import SwiftUI

struct CustomSearchBar: View {
    @Binding var text: String
    
    var isFocused: FocusState<Bool>.Binding
    
    let placeHolderText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .onTapGesture {
                    isFocused.wrappedValue = true
                }

            TextField(placeHolderText, text: $text)
                .textFieldStyle(.plain)
                .focused(isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                    isFocused.wrappedValue = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .glassEffect(in: Capsule())
        .overlay { // animated border
            if isFocused.wrappedValue {
                TimelineView(.animation) { context in
                    let angle = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2) / 2 * 360

                    Capsule()
                        .stroke(
                            AngularGradient(
                                colors: [.blue, .pink, .blue],
                                center: .center,
                                angle: .degrees(angle)
                            ),
                            lineWidth: 2
                        )
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused.wrappedValue = true
        }
    }
}

#Preview {
    @Previewable @State var searchText = ""
    @Previewable @FocusState var isFocused: Bool
    CustomSearchBar(text: $searchText, isFocused: $isFocused, placeHolderText: "Place holder")
        .padding()
}
