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
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    selectAllText()
                }
            }
    }
}

// for weights because they are doubles
struct EditableStatDouble: View {
    @Binding var value: Double
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", value: $value, format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .onChange(of: isFocused) { _, newValue in
                if newValue { selectAllText() }
            }
    }
}

struct EditableTitle: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Exercise name", text: $name)
            .focused($isFocused)
            .padding(4)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    selectAllText()
                }
            }
    }
}

extension View {
    func selectAllText() {
        // Dispatching to the main queue ensures the keyboard/field has fully become first responder
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
        }
    }
}
