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
        // capped at 2 decimals because converting a weight into kilograms otherwise fills the
        // field with a long trail of decimals
        TextField("", value: $value, format: .number.precision(.fractionLength(0...2)))
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

// for durations. The value is in seconds but it is shown as 00:00 so 60 -> 01:00
// the digits type in from the right like a stopwatch, so typing 1 then 0 then 1 shows 01:01 and the value becomes 61
struct EditableTime: View {
    @Binding var value: Int
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    // at most 6 digits so the field can still reach HH:MM:SS
    private static let maxDigits = 6

    var body: some View {
        // a text field takes all the width it is offered, so a hidden copy of the digits it is
        // showing is what holds it to their width instead
        ZStack {
            Text(widthTemplate)
                .monospacedDigit()
                .hidden()

            // the placeholder keeps the current time visible while the field is empty and waiting for digits
            TextField(SecondsFormatted(value), text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .textFieldStyle(.plain)
                // without this the field resizes as the digits change, since 1 is narrower than 0
                .monospacedDigit()
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .animation(.easeInOut(duration: 0.15), value: isFocused)
                .onChange(of: text) { _, newText in
                    guard isFocused else { return }
                    // only the last few digits matter, everything the user types before that has been shifted off the left
                    let digits = String(newText.filter(\.isNumber).suffix(Self.maxDigits))
                    value = secondsFrom(digits)

                    let formatted = digitsFormatted(digits)
                    if formatted != newText { text = formatted }
                }
                .onChange(of: isFocused) { _, focused in
                    // emptying the field on focus is what lets the digits shift in from the right
                    text = focused ? "" : SecondsFormatted(value)
                }
                .onChange(of: value) { _, newValue in
                    if !isFocused { text = SecondsFormatted(newValue) }
                }
                .onAppear { text = SecondsFormatted(value) }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    // measured off the text being typed rather than the value, since six digits can still add up to
    // under an hour, leaving the field showing 00:01:01 while the value formats as 01:01
    private var widthTemplate: String {
        let shown = text.isEmpty ? SecondsFormatted(value) : text

        return shown.count > 5 ? "00:00:00" : "00:00"
    }

    // "101" -> 61. The digits fill seconds first, then minutes, then hours
    private func secondsFrom(_ digits: String) -> Int {
        let number = Int(digits) ?? 0

        if digits.count > 4 {
            return (number / 10000) * 3600 + ((number / 100) % 100) * 60 + number % 100
        }

        return (number / 100) * 60 + number % 100
    }

    // "101" -> "01:01". Pads out to MM:SS, or to HH:MM:SS once there are more than four digits
    private func digitsFormatted(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }

        let width = digits.count > 4 ? 6 : 4
        let padded = String(repeating: "0", count: width - digits.count) + digits

        return stride(from: 0, to: width, by: 2)
            .map { String(padded.dropFirst($0).prefix(2)) }
            .joined(separator: ":")
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

// one labelled column of a duration picker, so "5 min" is a wheel of numbers next to its unit
@ViewBuilder
func wheel(range: Range<Int>, selection: Binding<Int>, unit: String) -> some View {
    HStack(spacing: 4) {
        Picker(unit, selection: selection) {
            ForEach(range, id: \.self) { value in
                Text("\(value)").tag(value)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 60)
        .clipped()

        Text(unit)
            .font(.callout)
            .foregroundStyle(Theme.grey)
            .frame(width: 44, alignment: .leading)
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
