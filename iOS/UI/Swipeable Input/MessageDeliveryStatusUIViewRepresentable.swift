//
//  LottieView.swift
//  Jibber
//
//  Created by Martin Young on 2/17/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import SwiftUI
import Lottie
import StreamChat

struct MessageDeliveryStatusUIViewRepresentable: UIViewRepresentable {

    enum ReadingState {
        case notReading
        case reading
    }

    @Binding var message: Messageable?
    @Binding var readingState: ReadingState

    func makeUIView(context: UIViewRepresentableContext<MessageDeliveryStatusUIViewRepresentable>) -> MessageDeliveryStatusView {
        return MessageDeliveryStatusView(readingState: self.$readingState)
    }

    func updateUIView(_ uiView: MessageDeliveryStatusView, context: Context) {
        guard let message = self.message else { return }

        uiView.update(with: message, readingState: self.readingState)
    }
}

class MessageDeliveryStatusView: BaseView {

    typealias ReadingState = MessageDeliveryStatusUIViewRepresentable.ReadingState

    var readingState: Binding<ReadingState>

    let readStatusView = AnimationView(name: "visibility")
    let deliveryStatusView = AnimationView(name: "checkmark")
    let errorStatusView = AnimationView(name: "alertCircle")
    let statusLabel = ThemeLabel(font: .small)

    init(readingState: Binding<ReadingState>) {
        self.readingState = readingState

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        // TODO: Make this configurable
        let keypath = AnimationKeypath(keys: ["**", "Color"])
        let colorProvider = ColorValueProvider(UIColor.green.lottieColorValue)

        self.addSubview(self.readStatusView)
        self.readStatusView.currentProgress = 1
        self.readStatusView.setValueProvider(colorProvider, keypath: keypath)
        self.readStatusView.animationSpeed = 0.1
        self.readStatusView.contentMode = .scaleAspectFit

        self.addSubview(self.deliveryStatusView)
        self.deliveryStatusView.currentProgress = 0
        self.deliveryStatusView.setValueProvider(colorProvider, keypath: keypath)
        self.deliveryStatusView.contentMode = .scaleAspectFit

        self.addSubview(self.errorStatusView)
        self.errorStatusView.currentProgress = 0
        self.errorStatusView.setValueProvider(colorProvider, keypath: keypath)
        self.errorStatusView.contentMode = .scaleAspectFit

        self.addSubview(self.statusLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.readStatusView.expandToSuperviewSize()
        self.deliveryStatusView.expandToSuperviewSize()
        self.errorStatusView.expandToSuperviewSize()
        self.statusLabel.expandToSuperviewSize()
    }

    func update(with message: Messageable, readingState: ReadingState) {
        self.readStatusView.isVisible = false
        self.deliveryStatusView.isVisible = false
        self.errorStatusView.isVisible = false
        self.statusLabel.isVisible = false

        if message.isFromCurrentUser {
            self.updateForCurrentUserMessage(message, readingState: readingState)
        } else {
            self.updateForNonUserMessage(message, readingState: readingState)
        }
    }

    private func updateForCurrentUserMessage(_ message: Messageable, readingState: ReadingState) {
        guard let chatMessage = MessageController.controller(message.streamCid,
                                                             messageId: message.id).message else { return }

        switch chatMessage.localState {
        case .pendingSync, .syncing, .pendingSend, .sending:
            // Show sending message ui
            self.statusLabel.isVisible = true
            self.statusLabel.text = "Sending"
        case .syncingFailed, .sendingFailed, .deletingFailed:
            self.errorStatusView.isVisible = true
        case .deleting:
            self.statusLabel.isVisible = true
            self.statusLabel.text = "Deleting"
        case .none:
            if chatMessage.isConsumed {
                self.deliveryStatusView.isVisible = true
            } else {
                self.readStatusView.isVisible = true
            }
        }

        switch readingState {
        case .notReading:
            self.errorStatusView.stop()
            self.deliveryStatusView.stop()

            if self.errorStatusView.isVisible {
                self.errorStatusView.currentProgress = 1
            }
            if self.deliveryStatusView.isVisible {
                self.deliveryStatusView.currentProgress = 1
            }
            if self.readStatusView.isVisible {
                self.readStatusView.currentProgress = 0
            }
        case .reading:
            if self.errorStatusView.isVisible && !self.errorStatusView.isAnimationPlaying {
                self.errorStatusView.play { finished in
                    self.readingState.wrappedValue = .notReading
                }
            }

            if self.deliveryStatusView.isVisible && !self.deliveryStatusView.isAnimationPlaying {
                self.deliveryStatusView.play { finished in
                    self.readingState.wrappedValue = .notReading
                }
            }
        }
    }

    private func updateForNonUserMessage(_ message: Messageable, readingState: ReadingState) {
        self.readStatusView.isVisible = true

        switch readingState {
        case .notReading:
            self.readStatusView.stop()
            if message.isConsumed {
                self.readStatusView.currentProgress = 0
            } else {
                self.readStatusView.currentProgress = 1
            }
        case .reading:
            if !self.readStatusView.isAnimationPlaying {//}&& uiView.currentProgress > 0 {
                self.readStatusView.play(fromProgress: 1, toProgress: 0, loopMode: .playOnce) { finished in
                    if finished {
                        self.readingState.wrappedValue = .notReading
                    }
                }
            }
        }
    }
}
