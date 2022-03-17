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

    @Binding var message: Messageable?
    @Binding var deliveryStatus: DeliveryStatus

    func makeUIView(context: UIViewRepresentableContext<MessageDeliveryStatusUIViewRepresentable>) -> MessageDeliveryStatusUIView {
        return MessageDeliveryStatusUIView()
    }

    func updateUIView(_ uiView: MessageDeliveryStatusUIView, context: Context) {
        guard let message = self.message else { return }

        uiView.update(with: message, deliveryStatus: self.deliveryStatus)
    }
}

class MessageDeliveryStatusUIView: BaseView {

    private let readStatusView = AnimationView.with(animation: .doubleCheckMark)
    private let sendStatus = AnimationView.with(animation: .checkMark)
    private let errorStatusView = AnimationView.with(animation: .alertCircle)

    override func initializeSubviews() {
        super.initializeSubviews()

        let keypath = AnimationKeypath(keys: ["**", "Color"])
        let colorProvider = ColorValueProvider(ThemeColor.white.color.lottieColorValue)

        self.addSubview(self.sendStatus)
        self.sendStatus.currentProgress = 0
        self.sendStatus.setValueProvider(colorProvider, keypath: keypath)
        self.sendStatus.contentMode = .scaleAspectFit

        self.addSubview(self.readStatusView)
        self.readStatusView.currentProgress = 0
        self.readStatusView.animationSpeed = 0.25
        self.readStatusView.setValueProvider(colorProvider, keypath: keypath)
        self.readStatusView.contentMode = .scaleAspectFit

        let errorColorProvider = ColorValueProvider(ThemeColor.red.color.lottieColorValue)

        self.addSubview(self.errorStatusView)
        self.errorStatusView.currentProgress = 0
        self.errorStatusView.setValueProvider(errorColorProvider, keypath: keypath)
        self.errorStatusView.contentMode = .scaleAspectFit
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.readStatusView.expandToSuperviewSize()
        self.sendStatus.expandToSuperviewSize()
        self.errorStatusView.expandToSuperviewSize()
    }

    private var previousMessage: Messageable?
    private var previousStatus: DeliveryStatus?

    func update(with message: Messageable, deliveryStatus: DeliveryStatus) {
        // Ignore redundant states
        guard message.id != self.previousMessage?.id
                || deliveryStatus != self.previousStatus else { return }

        defer {
            self.previousMessage = message
            self.previousStatus = deliveryStatus
        }

        self.readStatusView.isVisible = false
        self.sendStatus.isVisible = false
        self.errorStatusView.isVisible = false

        switch deliveryStatus {
        case .sending:
            break
        case .sent:
            if !message.isFromCurrentUser {
                self.readStatusView.isVisible = true
                self.readStatusView.currentProgress = 1
            } else {
                self.sendStatus.isVisible = true
                if self.previousStatus == .sending {
                    self.sendStatus.stop()
                    self.sendStatus.play()
                } else {
                    self.sendStatus.currentProgress = 1
                }
            }
        case .reading:
            self.readStatusView.isVisible = true
            self.readStatusView.currentProgress = 0
            self.readStatusView.play(fromProgress: 0, toProgress: 1, loopMode: .playOnce)
        case .read:
            self.readStatusView.isVisible = true
            self.readStatusView.currentProgress = 1
        case .error:
            self.errorStatusView.isVisible = true
            self.errorStatusView.stop()
            self.errorStatusView.play()
        }
    }
}
