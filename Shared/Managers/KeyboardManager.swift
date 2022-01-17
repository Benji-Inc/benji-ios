//
//  KeyboardManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

extension UIResponder {

    private weak static var currentFirstResponder: UIResponder?

    static var firstReponder: UIResponder? {
        UIResponder.currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)),
                                        to: nil,
                                        from: nil,
                                        for: nil)
        return UIResponder.currentFirstResponder
    }

    @objc private func findFirstResponder(sender: AnyObject) {
        UIResponder.currentFirstResponder = self
    }
}


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

    private func addKeyboardObservers() {

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .mainSink { (notification) in
                let inputAccessoryHeight = self.getInputAccessoryHeight()

                if notification.keyboardEndFrame.height > inputAccessoryHeight {
                    self.currentEvent = .willShow(notification)
                    self.cachedKeyboardEndFrame = notification.keyboardEndFrame
                    logDebug("keyboard will show")
                }
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .mainSink { (notification) in
                let inputAccessoryHeight = self.getInputAccessoryHeight()

                if notification.keyboardEndFrame.height > inputAccessoryHeight {
                    self.currentEvent = .didShow(notification)
                    self.cachedKeyboardEndFrame = notification.keyboardEndFrame
                    self.isKeyboardShowing = true

                    logDebug("keyboard did show")
                }
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .mainSink { (notification) in
                self.currentEvent = .willHide(notification)
                self.cachedKeyboardEndFrame = notification.keyboardEndFrame
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .mainSink { (notification) in
                self.currentEvent = .didHide(notification)
                self.cachedKeyboardEndFrame = notification.keyboardEndFrame

                self.isKeyboardShowing = false
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .mainSink { (notification) in
                self.currentEvent = .willChangeFrame(notification)
                self.cachedKeyboardEndFrame = notification.keyboardEndFrame
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)
            .mainSink { (notification) in
                self.currentEvent = .didChangeFrame(notification)
                self.cachedKeyboardEndFrame = notification.keyboardEndFrame
            }.store(in: &self.cancellables)
    }

    private func getInputAccessoryHeight() -> CGFloat {
        var inputAccessoryHeight: CGFloat = 0
        if let responder = UIResponder.firstReponder,
           let inputAccessoryView = responder.inputAccessoryView {

            inputAccessoryHeight = inputAccessoryView.height
        }

        return inputAccessoryHeight
    }
}

private extension NotificationCenter.Publisher.Output {

    var keyboardEndFrame: CGRect {
        let rect = self.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        return rect
    }
}
