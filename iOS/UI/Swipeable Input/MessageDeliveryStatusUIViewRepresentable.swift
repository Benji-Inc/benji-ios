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
        return MessageDeliveryStatusView()
    }

    func updateUIView(_ uiView: MessageDeliveryStatusView, context: Context) {
        guard let message = self.message else { return }

        uiView.update(with: message, readingState: self.readingState)
    }
}

class MessageDeliveryStatusView: BaseView {

    typealias ReadingState = MessageDeliveryStatusUIViewRepresentable.ReadingState

    let readStatusView = AnimationView(name: "visibility")
    let deliveryStatusView = AnimationView(name: "checkmark")
    let errorStatusView = AnimationView(name: "alertCircle")
    let statusLabel = ThemeLabel(font: .small)

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
        self.statusLabel.text = "Sending"

        self.pin(.right)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.readStatusView.expandToSuperviewSize()
        self.deliveryStatusView.expandToSuperviewSize()
        self.errorStatusView.expandToSuperviewSize()

        self.statusLabel.sizeToFit()
        self.statusLabel.centerOnXAndY()
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
