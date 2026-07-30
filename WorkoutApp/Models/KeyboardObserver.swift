//
//  KeyboardObserver.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-27.
//

import SwiftUI
import Combine

@Observable
class KeyboardObserver {
    var isVisible = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in self?.isVisible = true }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in self?.isVisible = false }
            .store(in: &cancellables)
    }
}
