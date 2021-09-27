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

    var currentItem: Connection?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .center
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

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.contentView.height)
        self.avatarView.pin(.top)
        self.avatarView.centerOnX()

        self.titleLabel.setSize(withWidth: self.contentView.width)
        self.titleLabel.match(.top, to: .bottom, of: self.avatarView, offset: 4)
        self.titleLabel.centerOnX()
    }
}
