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

    static let shared = KeyboardManager()

    private var cancellables = Set<AnyCancellable>()

    @Published var currentEvent: KeyboardEvent = .none
    // Includes the inputAccessoryViews size
    @Published var cachedKeyboardEndFrame: CGRect = .zero
    // Does not include the inputAccessoryViews size
    @Published var isKeyboardShowing: Bool = false

    // Does not include the inputAccessoryViews size
    @Published var willKeyboardShow: Bool = false

    private(set) weak var inputAccessoryView: UIView?

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

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    func reset() {
        self.cachedKeyboardEndFrame = .zero
        self.inputAccessoryView = nil
        self.willKeyboardShow = false
        self.isKeyboardShowing = false
    }

    func addKeyboardObservers(with inputAccessoryView: UIView? = nil) {
        self.inputAccessoryView = inputAccessoryView

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .mainSink { (notification) in
                self.currentEvent = .willShow(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)

                if let inputView = self.inputAccessoryView {
                    let willShow = self.cachedKeyboardEndFrame.height > inputView.height
                    self.willKeyboardShow = willShow
                } else {
                    self.willKeyboardShow = true
                }
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .mainSink { (notification) in
                self.currentEvent = .didShow(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)

                if let inputView = self.inputAccessoryView {
                    let isShowing = self.cachedKeyboardEndFrame.height > inputView.height
                    self.isKeyboardShowing = isShowing
                } else {
                    self.isKeyboardShowing = true
                }

            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .mainSink { (notification) in
                self.currentEvent = .willHide(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)
                if let inputView = self.inputAccessoryView {
                    let willShow = self.cachedKeyboardEndFrame.height > inputView.height
                    self.willKeyboardShow = willShow
                } else {
                    self.willKeyboardShow = true
                }
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .mainSink { (notification) in
                self.currentEvent = .didHide(notification)
                self.cachedKeyboardEndFrame = self.getFrame(for: notification)

                // For some reason the cached frame represents the superview in this scenario. 
                if let inputView = self.inputAccessoryView {
                    let isShowing = self.cachedKeyboardEndFrame.height > inputView.height
                    self.isKeyboardShowing = isShowing
                } else {
                    self.isKeyboardShowing = false
                }
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
