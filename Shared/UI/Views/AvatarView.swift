//
//  AvatarView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/23/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class AvatarView: DisplayableImageView {
    
    // MARK: - Properties

    var initials: String? {
        didSet {
            self.setImageFrom(initials: self.initials)
        }
    }

    private let label = ThemeLabel(font: .regularBold)

    private func setImageFrom(initials: String?) {
        guard let initials = initials else {
            self.label.text = nil
            return
        }

        self.label.isHidden = false
        self.label.setText(initials.uppercased())
        self.label.textAlignment = .center
        self.state = .success
        self.layoutNow()
    }

    func getSize(for height: CGFloat) -> CGSize {
        return CGSize(width: height, height: height)
    }

    func setSize(for height: CGFloat) {
        self.size = self.getSize(for: height)
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.insertSubview(self.label, aboveSubview: self.imageView)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.layer.masksToBounds = true
        self.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = Theme.innerCornerRadius
        self.imageView.set(backgroundColor: .B3)
        
        self.blurView.layer.masksToBounds = true
        self.blurView.layer.cornerRadius = Theme.innerCornerRadius

        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)
    }

    // MARK: - Open setters

    func set(avatar: PersonType?) {
        Task {
            guard let avatar = avatar else { return }

            if let user = avatar as? User, user.isDataAvailable {
                self.subscribeToUpdates(for: user)
            } else if let userId = avatar.userObjectId,
                      let user = await UserStore.shared.findUser(with: userId) {
                self.subscribeToUpdates(for: user)
            }
        }.add(to: self.taskPool)
        
        self.avatar = avatar

        self.displayable = avatar
    }
    
    func subscribeToUpdates(for user: User) {
        UserStore.shared.$userUpdated.filter { updatedUser in
            updatedUser?.objectId == user.userObjectId
        }.mainSink { [unowned self] updatedUser in
            guard let user = updatedUser else { return }
            self.didRecieveUpdateFor(user: user)
        }.store(in: &self.cancellables)
    }
    
    func didRecieveUpdateFor(user: User) {
        self.displayable = user
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.expandToSuperviewSize()
    }
}

fileprivate extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
