//
//  PersonView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/23/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class PersonView: DisplayableImageView {
    
    // MARK: - Properties

    func getSize(forHeight height: CGFloat) -> CGSize {
        return CGSize(width: height, height: height)
    }

    func setSize(forHeight height: CGFloat) {
        self.size = self.getSize(forHeight: height)
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.imageView.contentMode = .scaleAspectFill
        self.imageView.layer.masksToBounds = true
        self.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = Theme.innerCornerRadius
        self.imageView.set(backgroundColor: .B3)
        
        self.blurView.layer.masksToBounds = true
        self.blurView.layer.cornerRadius = Theme.innerCornerRadius

        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)

        self.subscribeToUpdates()
    }

    // MARK: - Open setters

    func set(person: PersonType?) {
        self.person = person

        self.displayable = person
    }

    // MARK: - Subscriptions

    /// Called when the currently assigned person receives an update to their state.
    func didRecieveUpdateFor(person: PersonType) {
        self.displayable = person
    }

    private func subscribeToUpdates() {
        PeopleStore.shared.$personUpdated
            .filter { [unowned self] updatedPerson in
                // Only handle person updates related to the currently assigned person.
                self.person?.personId ==  updatedPerson?.personId
            }.mainSink { [unowned self] updatedPerson in
                guard let updatedPerson = updatedPerson else { return }
                self.didRecieveUpdateFor(person: updatedPerson)
            }.store(in: &self.cancellables)
    }
}
