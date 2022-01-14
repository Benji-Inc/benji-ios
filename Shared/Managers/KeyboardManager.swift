//
//  KeyboardManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class KeyboardManager {

    /// Keyboard events that can happen. Translates directly to `UIKeyboard` notifications from UIKit.
    enum KeyboardEvent {
        case willShow(NotificationCenter.Publisher.Output)
        case didShow(NotificationCenter.Publisher.Output)
        case willHide(NotificationCenter.Publisher.Output)
        case didHide(NotificationCenter.Publisher.Output)
        case willChangeFrame(NotificationCenter.Publisher.Output)
        case didChangeFrame(NotificationCenter.Publisher.Output)
        case none // No event has happened
    }

    static let shared = KeyboardManager()

    private var cancellables = Set<AnyCancellable>()

    @Published var currentEvent: KeyboardEvent = .none
    @Published var cachedKeyboardEndFrame: CGRect = .zero
    var isKeyboardShowing: Bool = false

    init() {
        self.addKeyboardObservers()
    }

    func reset() {
        logDebug("RESET")
        self.cachedKeyboardEndFrame = .zero
        self.isKeyboardShowing = false
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        self.cancellables.removeAll()
    }

    private func addKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .mainSink { (notification) in
                logDebug("keyboard will show")
                self.currentEvent = .willShow(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .mainSink { (notification) in
                logDebug("keyboard did show")
                self.currentEvent = .didShow(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)

                self.isKeyboardShowing = true
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .mainSink { (notification) in
                logDebug("keyboard will hide")
                self.currentEvent = .willHide(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .mainSink { (notification) in
                self.currentEvent = .didHide(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)

                self.isKeyboardShowing = false
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .mainSink { (notification) in
                self.currentEvent = .willChangeFrame(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)
            .mainSink { (notification) in
                self.currentEvent = .didChangeFrame(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)
            }.store(in: &self.cancellables)
    }

    private func getFrame(for notification: NotificationCenter.Publisher.Output) -> CGRect {
        let rect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        return rect
    }
}
