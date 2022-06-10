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
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.personView)
    }

    func configure(with item: String) {
        Task {
            guard let person = await PeopleStore.shared.getPerson(withPersonId: item) else { return }            
            self.personView.set(person: person)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.expandToSuperviewSize()        
    }
}
