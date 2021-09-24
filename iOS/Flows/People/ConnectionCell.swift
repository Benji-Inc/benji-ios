//
//  NewConversationCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie

class ConnectionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Connection

    private let avatarView = AvatarView()
    private let titleLabel = Label(font: .regularBold, textColor: .lightPurple)
    private let animationView = AnimationView.with(animation: .checkbox)

    var didTapButton: CompletionOptional = nil
    var currentItem: Connection?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.animationView)
    }


    func configure(with item: Connection) {
        guard let nonMeUser = item.nonMeUser else { return }

        Task {
            do {
                let userWithData = try await nonMeUser.retrieveDataIfNeeded()

                Task.onMainActor {
                    self.avatarView.set(avatar: userWithData)
                    self.titleLabel.setText(userWithData.givenName)
                    self.layoutNow()
                }
            } catch {
                logDebug(error)
            }
        }
    }

    override func update(isSelected: Bool) {
        let progress: AnimationProgressTime = isSelected ? 1.0 : 0.0
        self.animationView.play(toProgress: progress)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.contentView.height - Theme.contentOffset)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.centerOnY()

        self.titleLabel.setSize(withWidth: self.contentView.width - Theme.contentOffset)
        self.titleLabel.match(.top, to: .bottom, of: self.avatarView, offset: 4)
        self.titleLabel.centerOnX()

        self.animationView.squaredSize = 20
        self.animationView.pin(.right, padding: Theme.contentOffset)
        self.animationView.centerOnY()
    }
}
