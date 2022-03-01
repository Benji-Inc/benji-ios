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

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.expandToSuperviewSize()
    }

    // MARK: - Open setters

    func set(avatar: PersonType?) {
        Task {
            guard let avatar = avatar else { return }

            self.subscribeToUpdates(for: avatar)
        }.add(to: self.taskPool)
        
        self.avatar = avatar

        self.displayable = avatar
    }
    
    func subscribeToUpdates(for person: PersonType) {
        PeopleStore.shared.$personUpdated.filter { updatedPerson in
            updatedPerson?.personId == person.personId
        }.mainSink { [unowned self] updatedPerson in
            guard let updatedPerson = updatedPerson else { return }
            self.didRecieveUpdateFor(person: updatedPerson)
        }.store(in: &self.cancellables)
    }
    
    func didRecieveUpdateFor(person: PersonType) {
        self.displayable = person
    }
}
