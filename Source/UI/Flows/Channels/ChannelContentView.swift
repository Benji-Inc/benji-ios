//
//  ChannelCellContentView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class ChannelContentView: View {

    private lazy var blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
    private lazy var blurView = UIVisualEffectView(effect: self.blurEffect)
    private lazy var vibrancyEffect = UIVibrancyEffect(blurEffect: self.blurEffect)
    private lazy var vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)

    private(set) var titleLabel = DisplayUnderlinedLabel()
    private let stackedAvatarView = StackedAvatarView()
    private let descriptionLabel = SmallLabel()
    private let dateLabel = ChannelDateLabel()

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
                self.descriptionLabel.set(text: text, color: .background4)
            }
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.addSubview(self.stackedAvatarView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.descriptionLabel)
        self.vibrancyEffectView.contentView.addSubview(self.dateLabel)
        self.blurView.contentView.addSubview(self.vibrancyEffectView)
        self.set(backgroundColor: .clear)
    }

    func configure(with type: ChannelType) {

        self.descriptionText = "Loading..."

        switch type {
        case .system(let channel):
            self.stackedAvatarView.set(items: channel.avatars)
        case .pending(_):
            break 
        case .channel(let channel):
            channel.getMembersAsUsers()
                .observeValue(with: { (users) in
                    runMain {
                        let notMeUsers = users.filter { (user) -> Bool in
                            return user.objectId != User.current()?.objectId
                        }

                        if let first = notMeUsers.first {
                            first.routine?.fetchIfNeededInBackground(block: { (object, error) in
                                if let routine = object as? Routine, let date = routine.date {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "h:mm a"
                                    let string = formatter.string(from: date)
                                    self.descriptionText = LocalizedString(id: "", arguments: [first.givenName, string], default: "@(name)'s routine is: @(routine)")
                                } else {
                                    self.descriptionText = LocalizedString(id: "", arguments: [first.givenName], default: "No routine set for @(name).")
                                }
                            })
                        } else {
                            self.descriptionText = "It's just you in here."
                        }

                        self.stackedAvatarView.set(items: notMeUsers)
                        self.layoutNow()
                    }
                })

            if let date = channel.dateUpdatedAsDate {
                self.dateLabel.set(date: date, color: .background3, alignment: .right)
            }

            if let context = channel.context {
                self.titleLabel.set(text: type.displayName, color: context.color)
            } else {
                self.titleLabel.set(text: type.displayName, color: .white)
            }

            self.layoutNow()
        }
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
        self.titleLabel.top = 6

        self.descriptionLabel.setSize(withWidth: width)
        self.descriptionLabel.left = self.titleLabel.left
        self.descriptionLabel.bottom = self.stackedAvatarView.bottom

        self.dateLabel.setSize(withWidth: self.width)
        self.dateLabel.right = self.width - Theme.contentOffset
        self.dateLabel.top = Theme.contentOffset
    }

    func reset() {
        self.titleLabel.text = nil
        self.descriptionLabel.text = nil
        self.stackedAvatarView.set(items: [])
    }
}
