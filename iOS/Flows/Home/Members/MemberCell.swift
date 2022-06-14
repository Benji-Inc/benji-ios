//
//  CircleCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MemberCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = String
    var currentItem: String?
    
    private let personView = BorderedPersonView()
    private let label = ThemeLabel(font: .regular)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.personView)
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
    }

    func configure(with item: String) {
        Task.onMainActorAsync {
    
            guard let person = await PeopleStore.shared.getPerson(withPersonId: item) else { return }            
            self.personView.set(person: person)
            if person.isCurrentUser {
                self.label.setText(person.givenName + " (You)")
            } else {
                self.label.setText(person.givenName)
            }
            self.layoutNow()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.pin(.bottom)
        self.label.centerOnX()
        
        self.personView.squaredSize = self.contentView.height - 30
        self.personView.centerOnX()
        self.personView.pin(.top)
    }
}
