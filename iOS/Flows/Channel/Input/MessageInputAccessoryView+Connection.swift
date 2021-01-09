//
//  MessageInputAccessoryView+Connection.swift
//  Benji
//
//  Created by Benji Dodgson on 6/6/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

extension MessageInputAccessoryView {
    
    func handleConnection(state: TCHClientConnectionState) {
        switch state {
        case .unknown, .disconnected, .connecting:
            self.expandingTextView.set(placeholder: "Connecting", color: .green)
            self.borderColor = Color.green.color.cgColor
            self.expandingTextView.isUserInteractionEnabled = false
            self.animationView.play()
        case .connected:
            if let activeChannel = self.activeChannel, case .channel(let channel) = activeChannel.channelType {
                self.setPlaceholder(with: channel)
            }
            self.expandingTextView.isUserInteractionEnabled = true
            self.animationView.stop()
            self.borderColor = nil
        case .denied:
            self.expandingTextView.set(placeholder: "Connection request denied", color: .red)
            self.expandingTextView.isUserInteractionEnabled = false
            self.animationView.stop()
            self.borderColor = Color.red.color.cgColor
        case .fatalError, .error:
            self.expandingTextView.set(placeholder: "Error connecting", color: .red)
            self.expandingTextView.isUserInteractionEnabled = false
            self.animationView.stop()
            self.borderColor = Color.red.color.cgColor
        @unknown default:
            break
        }

        self.layoutNow()
    }

    private func setPlaceholder(with channel: TCHChannel) {
        channel.getUsers(excludeMe: true)
            .mainSink(receiveResult: { (users, error) in
                guard let users = users else { return }
                self.expandingTextView.setPlaceholder(for: users)
            }).store(in: &self.cancellables)
    }
}
