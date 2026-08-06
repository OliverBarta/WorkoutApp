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

            TextField(placeHolderText, text: $text)
                .textFieldStyle(.plain)
                .focused(isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .glassEffect(in: Capsule())
    }
}

#Preview {
    @Previewable @State var searchText = ""
    @Previewable @FocusState var isFocused: Bool
    CustomSearchBar(text: $searchText, isFocused: $isFocused, placeHolderText: "Place holder")
        .padding()
}
