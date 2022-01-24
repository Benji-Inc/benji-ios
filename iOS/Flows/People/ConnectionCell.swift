//
//  ConversationCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie

class ConnectionCell: PersonCell, ManageableCell {
    typealias ItemType = Connection

    var currentItem: Connection?

    func configure(with item: Connection) {
        guard let nonMeUser = item.nonMeUser else { return }

        Task {
            await self.loadData(for: nonMeUser)
        }
    }
    
    @MainActor
    func loadData(for user: User) async {
        guard let userWithData = try? await user.retrieveDataIfNeeded() else { return }
        self.titleLabel.setText(userWithData.givenName)
        self.layoutNow()
    }
}
