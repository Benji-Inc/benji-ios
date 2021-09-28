//
//  InvitationLoadingView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import TMROLocalization

class InvitationLoadingView: View {

    let blurView = UIVisualEffectView(effect: nil)
    let avatarView = AvatarView()
    let label = Label(font: .medium)
    let progressView = UIProgressView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.addSubview(self.avatarView)
        self.addSubview(self.label)
        self.addSubview(self.progressView)
    }

    @MainActor
    func initiateLoading(with contact: Contact) async {

        self.resetAnimation()
        self.set(contact: contact)

        await UIView.animateKeyframes(withDuration: 1.0, delay: 0.1, options: []) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.blurView.effect = UIBlurEffect(style: .dark)
            }

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.avatarView.alpha = 1.0
                self.avatarView.transform = .identity
                self.label.alpha = 1.0
                self.label.transform = .identity
                self.progressView.alpha = 1.0
            }
        }
    }

    private func set(contact: Contact) {
        self.avatarView.set(avatar: contact)
        let text = LocalizedString(id: "", arguments: [contact.fullName], default: "Preparing message to: @(contact)")
        self.label.setText(text)
        self.layoutNow()
    }

    private func resetAnimation() {
        self.blurView.effect = nil
        self.avatarView.alpha = 0
        self.avatarView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        self.label.alpha = 0
        self.label.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        self.progressView.alpha = 0
        self.progressView.progress = 0.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.avatarView.setSize(for: 60)
        self.avatarView.centerOnX()
        self.avatarView.centerY = self.height * 0.4

        self.label.setSize(withWidth: self.width - Theme.contentOffset.doubled)
        self.label.centerOnX()
        self.label.match(.top, to: .bottom, of: self.avatarView, offset: Theme.contentOffset)

        self.progressView.width = self.halfWidth
        self.progressView.match(.top, to: .bottom, of: self.label, offset: Theme.contentOffset.half)
        self.progressView.centerOnX()
    }
}
