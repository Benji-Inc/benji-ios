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

    func makeUIView(context: UIViewRepresentableContext<MessageDeliveryStatusUIViewRepresentable>) -> AnimationView {
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit

        let animation = Animation.named("visibility")
        animationView.animation = animation


        // TODO: Make this configurable
        animationView.animationSpeed = 0.1
        animationView.currentProgress = 1

        return animationView
    }

    func updateUIView(_ uiView: AnimationView, context: Context) {
        guard let message = self.message else { return }


        switch self.readingState {
        case .notReading:
            uiView.stop()
            if message.isConsumed {
                uiView.currentProgress = 0
            } else {
                uiView.currentProgress = 1
            }
        case .reading:
            if !uiView.isAnimationPlaying {//}&& uiView.currentProgress > 0 {
                uiView.play(fromProgress: 1, toProgress: 0, loopMode: .playOnce) { finished in
                    if finished {
                        self.readingState = .notReading
                    }
                }
            }
        }
    }
}

private class MessageDeliveryStatusView: BaseView {

    typealias ReadingState = MessageDeliveryStatusUIViewRepresentable.ReadingState

    let readStatusView = AnimationView(name: "visibility")
    let deliveryStatusView = AnimationView(name: "checkmark")
    let statusLabel = ThemeLabel(font: .small)

    override func initializeSubviews() {
        super.initializeSubviews()

        // TODO: Make this configurable
        let keypath = AnimationKeypath(keys: ["**", "Color"])
        let colorProvider = ColorValueProvider(UIColor.green.lottieColorValue)

        self.addSubview(self.readStatusView)
        self.readStatusView.currentProgress = 1
        self.readStatusView.setValueProvider(colorProvider, keypath: keypath)

        self.addSubview(self.deliveryStatusView)
        self.deliveryStatusView.currentProgress = 0
        self.deliveryStatusView.setValueProvider(colorProvider, keypath: keypath)

        self.addSubview(self.statusLabel)
        self.statusLabel.text = "Sending"
        self.statusLabel.sizeToFit()
        self.pin(.right)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.readStatusView.expandToSuperviewSize()
        self.deliveryStatusView.expandToSuperviewSize()
    }

    func update(with message: Messageable, readingState: ReadingState) {
        if message.isFromCurrentUser {
            self.updateForCurrentUserMessage(message, readingState: readingState)
        } else {
            self.updateForNonUserMessage(message, readingState: readingState)
        }
    }

    private func updateForCurrentUserMessage(_ message: Messageable, readingState: ReadingState) {
        self.readStatusView.isVisible = false
        self.deliveryStatusView.isVisible = true
        self.statusLabel.isVisible = true

        guard let chatMessage = MessageController.controller(try! ConversationId(cid: message.conversationId),
                                                             messageId: message.id).message else { return }

        if let localState = chatMessage.localState {
            switch localState {
            case .pendingSync, .syncing, .pendingSend, .sending:
                break
            case .syncingFailed, .sendingFailed, .deletingFailed:
                break
            case .deleting:
                break
            }
        }

        switch readingState {
        case .notReading:
            break
        case .reading:
            break
        }
    }

    private func updateForNonUserMessage(_ message: Messageable, readingState: ReadingState) {
        self.readStatusView.isVisible = true
        self.deliveryStatusView.isVisible = false
        self.statusLabel.isVisible = false

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
//                        self.readingState = .notReading
                    }
                }
            }
        }
    }
}
