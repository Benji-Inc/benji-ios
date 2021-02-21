//
//  MessageInputAccessoryView+Connection.swift
//  Benji
//
//  Created by Benji Dodgson on 6/6/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

extension InputAccessoryView {
    
    func handleConnection(state: TCHClientConnectionState) {
        switch state {
        case .unknown, .disconnected, .connecting:
            self.textView.set(placeholder: "Connecting", color: .green)
            self.borderColor = Color.green.color.cgColor
            self.textView.isUserInteractionEnabled = false
            self.animationView.play()
        case .connected:
            if let activeChannel = self.activeChannel, case .channel(let channel) = activeChannel.channelType {
                self.setPlaceholder(with: channel)
            }
            self.textView.isUserInteractionEnabled = true
            self.animationView.stop()
            self.borderColor = nil
        case .denied:
            self.textView.set(placeholder: "Connection request denied", color: .red)
            self.textView.isUserInteractionEnabled = false
            self.animationView.stop()
            self.borderColor = Color.red.color.cgColor
        case .fatalError, .error:
            self.textView.set(placeholder: "Error connecting", color: .red)
            self.textView.isUserInteractionEnabled = false
            self.animationView.stop()
            self.borderColor = Color.red.color.cgColor
        @unknown default:
            break
        }

        self.layoutNow()
    }

    private func setPlaceholder(with channel: TCHChannel) {
        channel.getUsers(excludeMe: true)
            .mainSink(receiveValue: { (users) in
                self.textView.setPlaceholder(for: users)
            }).store(in: &self.cancellables)
    }
}
