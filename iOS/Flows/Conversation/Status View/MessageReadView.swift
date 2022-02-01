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
        case sent
        case reading
        case readCollapsed
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
        self.imageView.tintColor = ThemeColor.red.color
        self.addSubview(self.label)

        self.progressView.width = 1
        self.progressView.set(backgroundColor: .T1)
        self.progressView.alpha = 0
        
        self.$state.mainSink { [unowned self] state in
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

        self.imageView.squaredSize = 18

        let maxWidth = self.maxWidth - self.padding.value.doubled - self.imageView.width
        self.label.setSize(withWidth: maxWidth)
        self.label.pin(.left, offset: self.padding)
        self.label.centerOnY()

        self.imageView.match(.left, to: .right, of: self.label, offset: self.padding)
        self.imageView.centerOnY()

        let width: CGFloat
        if self.imageView.image.isNil {
            width = (self.padding.value * 2) + self.label.width
        } else {
            width = (self.padding.value * 3) + self.imageView.width + self.label.width
        }
        self.width = clamp(width, self.minWidth, self.maxWidth)

        self.progressView.expandToSuperviewHeight()
        self.progressView.pin(.left)
    }
    
    func handle(state: State) {
        switch state {
        case .initial:
            break
        case .sending:
            break
        case .sent:
            break
        case .reading:
            break
        case .readCollapsed:
            break
        case .read(let message):
            break
        case .error(let message):
            break
        }
    }
    
    private func handleInitial() {
        
    }
    
    private func handleSending() {
        
    }
    
    private func handleSent() {
        
    }
    
    private func handleReading() {
        
    }
    
    private func handleReadCollapsed() {
        
    }
    
    private func handleRead(with message: String) {
        
    }
    
    private func handleError(with message: String) {
        
    }

    @MainActor
    func configure(for message: Message) {
        self.reset()

        if message.isConsumed {
            if !message.isFromCurrentUser {
                self.label.setText("Read")
                self.imageView.image = UIImage(named: "checkmark-double")
            } else if !message.isConsumedByMe {
                self.label.setText("Read")
                self.imageView.image = UIImage(named: "checkmark-double")
            }
        } else if !message.isConsumed, message.localState.isNil {
            if message.isFromCurrentUser {
                self.label.setText("Delivered \(message.context.displayName)")
            } else {
                self.label.setText("Reading")
            }
            self.imageView.image = UIImage(named: "checkmark")
        } else if let state = message.localState {
            switch state {
            case .pendingSync, .syncing:
                self.label.setText("Syncing")
            case .syncingFailed, .sendingFailed:
                self.label.setText("Error")
            case .pendingSend, .sending:
                self.label.setText("Sending")
                Task {
                    await Task.snooze(seconds: 0.1)
                    guard !Task.isCancelled else { return }
                    if let message = ChatClient.shared.messageController(for: message)?.message {
                        self.configure(for: message)
                    }
                }.add(to: self.taskPool)
            case .deleting:
                break
            case .deletingFailed:
                break
            }
        } else {
            self.label.setText("Error")
        }
        
        self.layoutNow()
    }

    func beginConsumption(for message: Message) {
        guard message.canBeConsumed else { return }

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

    func reset() {
        if let animator = self.animator, animator.isRunning {
            animator.stopAnimation(true)
            animator.finishAnimation(at: .start)
        }

        self.label.text = nil
        self.imageView.image = nil

        self.progressView.alpha = 0
        self.progressView.width = 0
    }
}
