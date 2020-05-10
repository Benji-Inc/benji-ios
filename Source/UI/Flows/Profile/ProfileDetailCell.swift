//
//  ProfileDetailCell.swift
//  Benji
//
//  Created by Benji Dodgson on 10/15/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ProfileDetailCell: UICollectionViewCell {

    let titleLabel = SmallLabel()
    let label = SmallBoldLabel()
    let lineView = View()
    let button = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeSubviews() {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.label)
        self.contentView.addSubview(self.lineView)
        self.contentView.addSubview(self.button)
        self.button.isHidden = true
        self.lineView.set(backgroundColor: .background3)
    }

    func configure(with item: ProfileItem, for user: User) {

        self.button.isHidden = true

        switch item {
        case .picture:
            break
        case .name:
            self.titleLabel.set(text: "Name")
            self.label.set(text: user.fullName)
        case .localTime:
            self.titleLabel.set(text: "Local Time")
            self.label.set(text: Date.nowInLocalFormat)
        case .routine:
            self.titleLabel.set(text: "Routine")
            self.getRoutine(for: user)
        case .invites:
            self.titleLabel.set(text: "Invites")
            self.getReservations(for: user)
        }

        self.contentView.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.size = CGSize(width: self.contentView.width - Theme.contentOffset, height: 20)
        self.titleLabel.left = 0
        self.titleLabel.top = 0

        self.label.size = self.titleLabel.size
        self.label.left = self.titleLabel.left
        self.label.top = self.titleLabel.bottom + 5

        self.lineView.size = CGSize(width: self.contentView.width, height: 2)
        self.lineView.left = self.titleLabel.left
        self.lineView.top = self.label.bottom + 5

        self.button.size = CGSize(width: 100, height: 40)
        self.button.centerOnY()
        self.button.right = self.contentView.right
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.titleLabel.text = nil
        self.label.text = nil
        self.button.isHidden = true
    }

    private func getRoutine(for user: User) {

        self.label.set(text: "NO ROUTINE SET")
        self.button.set(style: .normal(color: .lightPurple, text: "Set"))
        self.button.isHidden = false

        user.routine?.fetchIfNeededInBackground(block: { (object, error) in
            if let routine = object as? Routine, let date = routine.date {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                let string = formatter.string(from: date)
                self.label.set(text: string)
                self.button.set(style: .normal(color: .lightPurple, text: "Update"))
            }

            self.contentView.layoutNow()
        })
    }

    private func getReservations(for user: User) {
        Reservation.getReservations(for: user)
            .observeValue { (reservations) in
                var numberOfUnclaimed: Int = 0

                reservations.forEach { (reservation) in
                    if !reservation.isClaimed {
                        numberOfUnclaimed += 1
                    }
                }

                var text = ""
                if numberOfUnclaimed == 0 {
                    text = "You have no reservations left."
                    self.button.isHidden = true
                } else {
                    text = "You have \(String(numberOfUnclaimed)) left."
                    self.button.isHidden = false
                }

                self.label.set(text: text)
                self.button.set(style: .normal(color: .lightPurple, text: "SHARE"))
        }
    }
}
