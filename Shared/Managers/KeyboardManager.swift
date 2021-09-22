//
//  KeyboardManager.swift
//  Ours
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
    @Published var cachedKeyboardFrame: CGRect = .zero
    // Does not include the inputAccessoryViews size
    @Published var isKeyboardShowing: Bool = false

    weak var inputAccessoryView: UIView?

    /// Keyboard events that can happen. Translates directly to `UIKeyboard` notifications from UIKit.
    enum KeyboardEvent {
        case willShow(NotificationCenter.Publisher.Output)
        case didShow(NotificationCenter.Publisher.Output)
        case willHide(NotificationCenter.Publisher.Output)
        case didHide(NotificationCenter.Publisher.Output)
        case willChangeFrame(NotificationCenter.Publisher.Output)
        case didChangeFrame(NotificationCenter.Publisher.Output)
        case none // No event has happe
    }

    init() {
        self.initialize()
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    private func initialize() {
        self.addKeyboardObservers()
    }

    func addKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .mainSink { (notification) in
                self.currentEvent = .willShow(notification)
                self.cachedKeyboardFrame = self.getFrame(for: notification)
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .mainSink { (notification) in
                self.currentEvent = .didShow(notification)
                self.cachedKeyboardFrame = self.getFrame(for: notification)

                if let inputView = self.inputAccessoryView {
                    self.isKeyboardShowing = self.cachedKeyboardFrame.height > inputView.height
                } else {
                    self.isKeyboardShowing = true
                }

            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .mainSink { (notification) in
                self.currentEvent = .willHide(notification)
                self.cachedKeyboardFrame = self.getFrame(for: notification)
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .mainSink { (notification) in
                self.currentEvent = .didHide(notification)
                self.cachedKeyboardFrame = self.getFrame(for: notification)

                // For some reason the cached frame represents the superview in this scenario. 
                if let superview = self.inputAccessoryView?.superview {
                    self.isKeyboardShowing = self.cachedKeyboardFrame.height > superview.height
                } else {
                    self.isKeyboardShowing = false
                }
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .mainSink { (notification) in
                self.currentEvent = .willChangeFrame(notification)
                self.cachedKeyboardFrame = self.getFrame(for: notification)
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)
            .mainSink { (notification) in
                self.currentEvent = .didChangeFrame(notification)
                self.cachedKeyboardFrame = self.getFrame(for: notification)
            }.store(in: &self.cancellables)
    }

    private func getFrame(for notification: NotificationCenter.Publisher.Output) -> CGRect {
        return notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
    }
}
