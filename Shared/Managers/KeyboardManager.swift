//
//  KeyboardManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import UIKit

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
        
        var name: String {
            switch self {
            case .willShow(_):
                return "willShow"
            case .didShow(_):
                return "didShow"
            case .willHide(_):
                return "willHide"
            case .didHide(_):
                return "didHide"
            case .willChangeFrame(_):
                return "willChangeFrame"
            case .didChangeFrame(_):
                return "didChangeFrame"
            case .none:
                return "none"
            }
        }
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
                guard !self.isKeyboardShowing else { return }

                let inputAccessoryHeight = self.getInputAccessoryHeight()

                if notification.keyboardEndFrame.height > inputAccessoryHeight {
                    self.currentEvent = .willShow(notification)
                    self.cachedKeyboardEndFrame = notification.keyboardEndFrame
                }
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .mainSink { (notification) in
                guard !self.isKeyboardShowing else { return }

                let inputAccessoryHeight = self.getInputAccessoryHeight()

                if notification.keyboardEndFrame.height > inputAccessoryHeight {
                    self.currentEvent = .didShow(notification)
                    self.cachedKeyboardEndFrame = notification.keyboardEndFrame
                    self.isKeyboardShowing = true
                }
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .mainSink { (notification) in
                guard self.isKeyboardShowing else { return }

                let inputAccessoryHeight = self.getInputAccessoryHeight()
                let keyboardFrameVisibleHeight = self.getKeyboardFrameVisibleHeight(for: notification)

                if keyboardFrameVisibleHeight <= inputAccessoryHeight {
                    self.currentEvent = .willHide(notification)
                    self.cachedKeyboardEndFrame = notification.keyboardEndFrame
                }

            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .mainSink { (notification) in
                guard self.isKeyboardShowing else { return }

                let inputAccessoryHeight = self.getInputAccessoryHeight()
                let keyboardFrameVisibleHeight = self.getKeyboardFrameVisibleHeight(for: notification)

                if keyboardFrameVisibleHeight <= inputAccessoryHeight {
                    self.currentEvent = .didHide(notification)
                    self.cachedKeyboardEndFrame = notification.keyboardEndFrame

                    self.isKeyboardShowing = false
                }
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
        guard let responder = UIResponder.firstResponder else {
            return inputAccessoryHeight
        }
        if let inputAccessoryView = responder.inputAccessoryView {
            inputAccessoryHeight = inputAccessoryView.height
        } else if let inputAccessoryView = responder.inputAccessoryViewController?.view {
            inputAccessoryHeight = inputAccessoryView.height
        }

        return inputAccessoryHeight
    }

    private func getKeyboardFrameVisibleHeight(for notification: NotificationCenter.Publisher.Output)
    -> CGFloat {

        let keyboardFrame = notification.keyboardEndFrame
        return UIScreen.main.bounds.height - keyboardFrame.top
    }
}

private extension NotificationCenter.Publisher.Output {

    var keyboardEndFrame: CGRect {
        let rect = self.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        return rect
    }
}
