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

    private let vibrancyView = VibrancyView()

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

        self.addSubview(self.vibrancyView)
        self.addSubview(self.stackedAvatarView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.descriptionLabel)
        self.descriptionLabel.lineBreakMode = .byTruncatingTail
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
            self.display(channel: channel)
        }

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.vibrancyView.expandToSuperviewSize()

        self.stackedAvatarView.left = Theme.contentOffset
        self.stackedAvatarView.top = Theme.contentOffset

        let width = self.width - self.stackedAvatarView.right - Theme.contentOffset * 2
        self.titleLabel.setSize(withWidth: width)
        let titleOffset: CGFloat = self.stackedAvatarView.width == 0 ? Theme.contentOffset : Theme.contentOffset + self.stackedAvatarView.right
        self.titleLabel.left = titleOffset
        self.titleLabel.pin(.top, padding: 6)

        self.descriptionLabel.height = 17
        self.descriptionLabel.width = width
        self.descriptionLabel.left = self.titleLabel.left
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: 8)
    }

    private func display(channel: TCHChannel) {

        channel.getUsers(excludeMe: true)
            .mainSink(receiveValue: { (users) in

                if !channel.friendlyName.isNil {
                    self.displayCustom(channel: channel)
                } else if users.count == 0 {
                    self.titleLabel.setText("You")
                    self.titleLabel.setTextColor(.white)
                    self.descriptionText = "It's just you in here."
                    self.layoutNow()
                } else if users.count == 1, let user = users.first(where: { user in
                    return user.objectId != User.current()?.objectId
                }) {
                    self.displayDM(for: channel, with: user)
                } else {
                    self.displayGroupChat(for: channel, with: users)
                }

                self.stackedAvatarView.set(items: users)
                self.layoutNow()

            }).store(in: &self.cancellables)

        self.layoutNow()
    }

    private func displayDM(for channel: TCHChannel, with user: User) {
        if let ritual = user.ritual {
            ritual.retrieveDataIfNeeded()
                .mainSink { result in
                    switch result {
                    case .success(let ritual):
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let string = formatter.string(from: ritual.date!)
                        self.descriptionText = LocalizedString(id: "", arguments: [string], default: "Ritual: @(ritual)")
                    case .error(_):
                        self.descriptionText = LocalizedString(id: "", arguments:[], default: "No ritual yet.")
                    }
                    self.layoutNow()
                }.store(in: &cancellables)
        } else {
            self.descriptionText = LocalizedString(id: "", arguments: [], default: "No ritual yet.")
        }

        self.titleLabel.setText(user.handle)
        self.titleLabel.setTextColor(.white)

        self.layoutNow()
    }

    func displayGroupChat(for channel: TCHChannel, with users: [User]) {
        var text = ""
        for (index, user) in users.enumerated() {
            if index < users.count - 1 {
                text.append(String("\(user.handle), "))
            } else if index == users.count - 1 && users.count > 1 {
                text.append(String("\(user.handle)"))
            } else {
                text.append(user.handle)
            }
        }

        self.titleLabel.setText("Group")
        self.titleLabel.setTextColor(.white)
        self.descriptionLabel.setText(text)
    }

    private func displayCustom(channel: TCHChannel) {
        if let name = channel.friendlyName {
            self.titleLabel.setText(name.capitalized)
            self.titleLabel.setTextColor(.white)
            self.descriptionText = channel.channelDescription
        }
    }

    func reset() {
        self.titleLabel.text = nil
        self.descriptionLabel.text = nil
        self.stackedAvatarView.set(items: [])
    }
}
