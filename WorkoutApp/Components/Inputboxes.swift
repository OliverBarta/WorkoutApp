//
//  Inputboxes.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-22.
//

import SwiftUI
import SwiftData

struct EditableStat: View {
    @Binding var value: Int
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", value: $value, format: .number)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .fixedSize()
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFocused ? Color(.tertiarySystemFill) : .clear)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct EditableTitle: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Exercise name", text: $name)
            .focused($isFocused)
            .fixedSize()
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFocused ? Color(.tertiarySystemFill) : .clear)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}
