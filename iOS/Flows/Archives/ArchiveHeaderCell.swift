//
//  ArchiveHeaderView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ArchiveHeaderCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = User

    var currentItem: User?

    let nameLabel = Label(font: .display)
    let ritualLabel = Label(font: .regular, textColor: .background4)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.ritualLabel)
    }

    func configure(with user: User) {
        user.retrieveDataIfNeeded()
            .mainSink(receiveValue: { user in
                self.nameLabel.setText(user.fullName)
                self.setTextFor(ritual: user.ritual)
                self.layoutNow()
            }).store(in: &self.cancellables)
    }

    func setTextFor(ritual: Ritual?) {
        if let r = ritual {
            r.fetchIfNeededInBackground(block: { (object, error) in
                if let ritual = object as? Ritual, let date = ritual.date {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a"
                    let string = formatter.string(from: date)
                    self.ritualLabel.setText("Ritual starts at: \(string)")
                    self.layoutNow()
                }
            })

        } else {
            self.ritualLabel.setText("No ritual set")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.nameLabel.setSize(withWidth: self.width)
        self.nameLabel.pin(.top, padding: Theme.contentOffset.half)
        self.nameLabel.pin(.left)

        self.ritualLabel.setSize(withWidth: self.width)
        self.ritualLabel.match(.top, to: .bottom, of: self.nameLabel, offset: 0)
        self.ritualLabel.pin(.left)
    }
}
