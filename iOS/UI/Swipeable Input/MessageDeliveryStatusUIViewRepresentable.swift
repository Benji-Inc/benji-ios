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

    enum UpdatingState {
        case notUpdating
        case updating
    }

    enum DeliveryStatus {
        case sending
        case sent
        case reading
        case read
        case error
    }

    @Binding var message: Messageable?
    @Binding var updatingState: UpdatingState

    func makeUIView(context: UIViewRepresentableContext<MessageDeliveryStatusUIViewRepresentable>) -> MessageDeliveryStatusUIView {
        return MessageDeliveryStatusUIView(readingState: self.$updatingState)
    }

    func updateUIView(_ uiView: MessageDeliveryStatusUIView, context: Context) {
        guard let message = self.message else { return }

        uiView.update(with: message, readingState: self.updatingState)
    }
}

class MessageDeliveryStatusUIView: BaseView {

    typealias ReadingState = MessageDeliveryStatusUIViewRepresentable.UpdatingState

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

        let keypath = AnimationKeypath(keys: ["**", "Color"])
        let colorProvider = ColorValueProvider(ThemeColor.D1.color.lottieColorValue)

        self.addSubview(self.readStatusView)
        self.readStatusView.currentProgress = 1
        self.readStatusView.setValueProvider(colorProvider, keypath: keypath)
        self.readStatusView.animationSpeed = 0.25
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
                self.readStatusView.isVisible = true
            } else {
                self.deliveryStatusView.isVisible = true
            }
        }

        switch readingState {
        case .notUpdating:
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
        case .updating:
            if self.errorStatusView.isVisible && !self.errorStatusView.isAnimationPlaying {
                self.errorStatusView.play { finished in
                    self.readingState.wrappedValue = .notUpdating
                }
            }

            if self.deliveryStatusView.isVisible && !self.deliveryStatusView.isAnimationPlaying {
                self.deliveryStatusView.play { finished in
                    self.readingState.wrappedValue = .notUpdating
                }
            }
        }
    }

    private func updateForNonUserMessage(_ message: Messageable, readingState: ReadingState) {
        self.readStatusView.isVisible = true

        switch readingState {
        case .notUpdating:
            self.readStatusView.stop()
            if message.isConsumed {
                self.readStatusView.currentProgress = 0
            } else {
                self.readStatusView.currentProgress = 1
            }
        case .updating:
            if !self.readStatusView.isAnimationPlaying {//}&& uiView.currentProgress > 0 {
                self.readStatusView.play(fromProgress: 1, toProgress: 0, loopMode: .playOnce) { finished in
                    if finished {
                        self.readingState.wrappedValue = .notUpdating
                    }
                }
            }
        }
    }
}
