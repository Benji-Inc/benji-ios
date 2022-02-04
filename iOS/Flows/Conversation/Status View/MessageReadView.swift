//
//  MessageReadView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import StreamChat

class MessageReadView: MessageStatusContainer {
    
    enum State {
        case initial
        case sending
        case syncing
        case delivered
        case reading(Message)
        case readCollapsed(Message)
        case read(String)
        case error(String)
    }

    let imageView = UIImageView()
    let label = ThemeLabel(font: .small)
    let progressView = BaseView()
    
    var cancellables = Set<AnyCancellable>()
    
    @Published var state: State = .initial
    
    private(set) var animator: UIViewPropertyAnimator?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.progressView)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(self.label)

        self.progressView.width = 1
        self.progressView.set(backgroundColor: .D6withAlpha)
        self.progressView.alpha = 0
        
        self.$state.mainSink { [weak self] state in
            guard let `self` = self else { return }
            self.handle(state: state)
        }.store(in: &self.cancellables)
    }
    
    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = 15
        self.label.height = 20
        
        switch self.state {
        case .initial:
            self.width = 0
        case .syncing, .sending, .reading, .error(_):
            // text, no image
            let maxWidth = self.maxWidth - self.padding.value.doubled - self.imageView.width
            self.label.setSize(withWidth: maxWidth)
            self.label.pin(.left, offset: self.padding)
            self.label.centerOnY()
            let width = (self.padding.value * 2) + self.label.width
            self.width = clamp(width, self.minWidth, self.maxWidth)
        case .delivered, .readCollapsed(_):
            // no text, image
            self.label.width = 0
            self.imageView.centerOnY()
            self.imageView.center.x = self.halfWidth
            self.width = self.minWidth
        case .read(_):
            let maxWidth = self.maxWidth - self.padding.value.doubled - self.imageView.width
            self.label.setSize(withWidth: maxWidth)
            self.label.pin(.left, offset: self.padding)
            self.label.centerOnY()
            
            self.imageView.match(.left, to: .right, of: self.label, offset: self.padding)
            self.imageView.centerOnY()
            
            let width = (self.padding.value * 3) + self.imageView.width + self.label.width
            self.width = clamp(width, self.minWidth, self.maxWidth)
        }

        self.progressView.expandToSuperviewHeight()
        self.progressView.pin(.left)
    }
    
    // Public
    
    @MainActor
    func configure(for message: Message) {
        // Need to reset each time or will crash.
        self.state = .initial

        if message.isConsumed {
            self.state = .readCollapsed(message)
        } else if !message.isConsumed, message.localState.isNil {
            self.state = .delivered
        } else if let state = message.localState {
            switch state {
            case .pendingSync, .syncing:
                self.state = .syncing
            case .syncingFailed, .sendingFailed:
                self.state = .error("Error")
            case .pendingSend, .sending:
                self.state = .sending
                Task {
                    await Task.snooze(seconds: 0.1)
                    guard !Task.isCancelled else { return }
                    if let message = ChatClient.shared.messageController(for: message)?.message {
                        self.configure(for: message)
                    }
                }.add(to: self.taskPool)
            case .deleting:
                self.state = .error("Deleting")
            case .deletingFailed:
                self.state = .error("Error")
            }
        } else {
            self.state = .error("Error")
        }
    }
    
    func beginConsumption(for message: Message) {
        guard message.canBeConsumed else {
            self.showRead(with: message)
            return
        }
        self.state = .reading(message)
    }
    
    func showRead(with message: Message) {
        guard let messageDate = message.lastReadAt else { return }
        let dateString = Date.hourMinuteTimeOfDay.string(from: messageDate)
        self.state = .read(dateString)
    }
        
    // Private
    
    private func handle(state: State) {
                
        switch state {
        case .initial:
            self.handleInitial()
        case .syncing:
            self.handleSyncing()
        case .sending:
            self.handleSending()
        case .delivered:
            self.handleDelivered()
        case .reading(let message):
            self.handleReading(with: message)
        case .readCollapsed(let message):
            self.handleReadCollapsed(with: message)
        case .read(let text):
            self.handleRead(with: text)
        case .error(let text):
            self.handleError(with: text)
        }
    }
    
    private func handleInitial() {
        if let animator = self.animator, animator.isRunning {
            animator.stopAnimation(true)
            animator.finishAnimation(at: .start)
        }

        self.label.text = nil
        self.label.alpha = 0
        self.imageView.alpha = 0

        self.progressView.alpha = 0
        self.progressView.width = 0
    }
    
    private func handleSyncing() {
        self.label.setText("Syncing")
        self.label.alpha = 1.0
        self.imageView.alpha = 0.0
        self.layoutNow()
    }
    
    private func handleSending() {
        self.label.setText("Sending")
        self.label.alpha = 1.0
        self.imageView.alpha = 0.0
        self.layoutNow()
    }
    
    private func handleDelivered() {
        self.label.setText("")
        self.imageView.image = UIImage(named: "checkmark")
        self.label.alpha = 0.0
        self.imageView.alpha = 1.0
        self.layoutNow()
    }
    
    private func handleReading(with message: Message) {
        self.label.setText("Reading")
        self.imageView.image = UIImage(named: "checkmark")
        self.label.alpha = 1.0
        self.imageView.alpha = 1.0
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.layoutNow()
        } completion: { _ in
            self.handleConsumption(with: message)
        }
    }
    
    private func handleConsumption(with message: Message) {
        self.progressView.alpha = 0
        self.progressView.width = 0

        let wordDuration: TimeInterval = Double(message.text.wordCount) * 0.2
        let duration: TimeInterval = clamp(wordDuration, 2.0, CGFloat.greatestFiniteMagnitude)

        self.animator = UIViewPropertyAnimator.init(duration: duration,
                                                    curve: .linear,
                                                    animations: {
            self.progressView.alpha = 0.5
            self.progressView.width = self.width
            self.layoutNow()
        })

        self.animator?.isInterruptible = true
        self.animator?.startAnimation()

        Task {
            await Task.snooze(seconds: duration)
            await UIView.awaitAnimation(with: .fast, animations: {
                self.progressView.alpha = 0
            })
            do {
                guard !Task.isCancelled else { return }
                try await message.setToConsumed()
            }
            catch {
                logError(error)
            }
        }.add(to: self.taskPool)
    }
    
    private func handleReadCollapsed(with message: Message) {
        self.label.setText("")
        self.imageView.image = UIImage(named: "checkmark-double")
        self.label.alpha = 0.0
        self.imageView.alpha = 1.0
        self.layoutNow()
    }
    
    private func handleRead(with text: String) {
        self.label.setText(text)
        self.imageView.image = UIImage(named: "checkmark-double")
        self.label.alpha = 1.0
        self.imageView.alpha = 1.0
        self.layoutNow()
    }
    
    private func handleError(with text: String) {
        self.label.setText(text)
        self.label.alpha = 1.0
        self.imageView.alpha = 0.0
        self.layoutNow()
    }
}
