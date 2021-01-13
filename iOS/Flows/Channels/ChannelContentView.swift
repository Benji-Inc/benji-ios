//
//  ChannelCellContentView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import TwilioChatClient
import Combine

class ChannelContentView: View {

    private lazy var blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
    private lazy var blurView = UIVisualEffectView(effect: self.blurEffect)
    private lazy var vibrancyEffect = UIVibrancyEffect(blurEffect: self.blurEffect)
    private lazy var vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)

    private(set) var titleLabel = Label(font: .displayUnderlined)
    private let stackedAvatarView = StackedAvatarView()
    private let descriptionLabel = Label(font: .small, textColor: .background4)
    private var cancellables = Set<AnyCancellable>()

    var descriptionText: Localized? {
        didSet {
            guard let text = self.descriptionText else { return }

            if let attributedText = self.descriptionLabel.attributedText, !attributedText.string.isEmpty {
                if attributedText.string != localized(text) {
                    self.descriptionLabel.fade(toText: localized(text)) { [unowned self] in
                        self.layoutNow()
                    }
                }
            } else {
                self.descriptionLabel.setText(text)
            }
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.addSubview(self.stackedAvatarView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.descriptionLabel)
        self.blurView.contentView.addSubview(self.vibrancyEffectView)
        self.set(backgroundColor: .clear)
        self.roundCorners()
    }

    func configure(with type: ChannelType) {

        switch type {
        case .system(let channel):
            self.stackedAvatarView.set(items: channel.avatars)
        case .pending(_):
            break 
        case .channel(let channel):
            if channel.friendlyName == "welcome" {
                self.displayWelcome(channel: channel)
            } else if channel.friendlyName == "feedback" {
                self.displayFeedback(channel: channel)
            } else {
                self.display(channel: channel)
            }
        }

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.vibrancyEffectView.expandToSuperviewSize()

        self.stackedAvatarView.left = Theme.contentOffset
        self.stackedAvatarView.top = Theme.contentOffset

        let width = self.width - self.stackedAvatarView.right - Theme.contentOffset * 2
        self.titleLabel.setSize(withWidth: width)
        let titleOffset: CGFloat = self.stackedAvatarView.width == 0 ? Theme.contentOffset : Theme.contentOffset + self.stackedAvatarView.right
        self.titleLabel.left = titleOffset
        self.titleLabel.pin(.top, padding: 6)

        self.descriptionLabel.setSize(withWidth: width)
        self.descriptionLabel.left = self.titleLabel.left
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: 8)
    }

    private func display(channel: TCHChannel) {

        channel.getUsers(excludeMe: true)
            .mainSink(receiveValue: { (users) in
                if let first = users.first {
                    if let ritual = first.ritual {
                        ritual.fetchIfNeededInBackground(block: { (object, error) in
                            if let ritual = object as? Ritual, let date = ritual.date {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "h:mm a"
                                let string = formatter.string(from: date)
                                self.descriptionText = LocalizedString(id: "", arguments: [first.givenName, string], default: "@(name)'s ritual is: @(ritual)")
                            } else {
                                self.descriptionText = LocalizedString(id: "", arguments: [first.givenName], default: "No ritual yet for @(name).")
                            }
                        })
                    } else {
                        self.descriptionText = LocalizedString(id: "", arguments: [first.givenName], default: "No ritual yet for @(name).")
                    }

                    if channel.isOwnedByMe {
                        self.titleLabel.setText(first.givenName)
                        self.titleLabel.setTextColor(.white)
                    } else if let author = users.first(where: { (user) -> Bool in
                        return user.id == channel.createdBy
                    }) {
                        self.titleLabel.setText(author.givenName)
                        self.titleLabel.setTextColor(.white)
                    }

                } else if let name = channel.friendlyName {
                    self.titleLabel.setText(name.capitalized)
                    self.titleLabel.setTextColor(.white)
                    self.descriptionText = "Start here to learn your way around."
                } else {
                    self.titleLabel.setText("You")
                    self.titleLabel.setTextColor(.white)
                    self.descriptionText = "It's just you in here."
                }

                self.stackedAvatarView.set(items: users)
                self.layoutNow()

            }).store(in: &self.cancellables)

        self.layoutNow()
    }

    private func displayWelcome(channel: TCHChannel) {
        if let name = channel.friendlyName {
            self.titleLabel.setText(name.capitalized)
            self.titleLabel.setTextColor(.white)
            self.descriptionText = "Start here to learn your way around."
        }
    }

    private func displayFeedback(channel: TCHChannel) {
        if let name = channel.friendlyName {
            self.titleLabel.setText(name.capitalized)
            self.titleLabel.setTextColor(.white)
            self.descriptionText = "Got something to say? Say it here!"
        }
    }

    func reset() {
        self.titleLabel.text = nil
        self.descriptionLabel.text = nil
        self.stackedAvatarView.set(items: [])
    }
}
