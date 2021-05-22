//
//  ArchiveHeaderView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import TMROLocalization

class UserHeaderCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = User

    var currentItem: User?

    func configure(with user: User) {
            user.retrieveDataIfNeeded()
                .mainSink(receiveValue: { user in
                    self.fetchRitual(for: user)
                    self.setNeedsUpdateConfiguration()
                }).store(in: &self.cancellables)
    }

    func fetchRitual(for user: User) {
        user.ritual?.retrieveDataIfNeeded()
            .mainSink(receivedResult: { result in

                var config = self.defaultContentConfiguration()
                let titleFont = FontType.display
                let title = NSAttributedString(string: user.fullName, attributes: [NSAttributedString.Key.font: titleFont.font,
                                                                                   NSAttributedString.Key.kern: titleFont.kern,
                                                                                   NSAttributedString.Key.foregroundColor: Color.white.color])
                config.attributedText =  title

                switch result {
                case .success(let ritual):
                    if let date = ritual.date {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let string = formatter.string(from: date)
                        let descriptionFont = FontType.regular
                        let description = NSAttributedString(string: "Ritual starts at: \(string)", attributes: [NSAttributedString.Key.font: descriptionFont.font,
                                                                                           NSAttributedString.Key.kern: descriptionFont.kern,
                                                                                           NSAttributedString.Key.foregroundColor: Color.background4.color])
                        config.secondaryAttributedText =  description
                    }
                case .error(_):
                    break
                }

                self.contentConfiguration = config
                //self.setNeedsUpdateConfiguration()
            }).store(in: &self.cancellables)
    }
}
