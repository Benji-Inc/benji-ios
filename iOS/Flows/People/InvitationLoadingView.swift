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
    let label = Label(font: .small)
    let progressView = UIProgressView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.addSubview(self.avatarView)
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.addSubview(self.progressView)
    }

    @MainActor
    func initiateLoading(with contact: Contact) async {

        self.resetAllViews()
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

        UIView.animate(withDuration: 2.0) {
            self.progressView.setProgress(1.0, animated: true)
        }

        await Task.sleep(seconds: 2.2)
    }

    @MainActor
    func update(contact: Contact) async {

        self.set(contact: contact)

        await UIView.animateKeyframes(withDuration: 1.0, delay: 0.1, options: []) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.resetAnimation()
            }

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.avatarView.alpha = 1.0
                self.avatarView.transform = .identity
                self.label.alpha = 1.0
                self.label.transform = .identity
                self.progressView.alpha = 1.0
            }
        }

        UIView.animate(withDuration: 2.0) {
            self.progressView.setProgress(1.0, animated: true)
        }

        await Task.sleep(seconds: 2.2)
    }

    func hideAllViews() async {
        await UIView.animateKeyframes(withDuration: 1.0, delay: 0.1, options: []) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.resetAnimation()
            }

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.blurView.effect = nil
            }
        }
    }

    private func set(contact: Contact) {
        self.avatarView.reset()
        self.avatarView.set(avatar: contact)
        let text = LocalizedString(id: "", arguments: [contact.fullName], default: "Preparing message for: @(contact)")
        self.label.setText(text)
        self.layoutNow()
    }

    private func resetAllViews() {
        self.blurView.effect = nil
        self.resetAnimation()
    }

    private func resetAnimation() {
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

        self.avatarView.setSize(for: 100)
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
