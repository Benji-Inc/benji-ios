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
    private let videoView = VideoView()
    private let label = ThemeLabel(font: .regular, textColor: .whiteWithAlpha)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.personView)
        // TODO: Layout and size the video view or add it to the person view.
        self.contentView.addSubview(self.videoView)
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.match(.top, to: .bottom, of: self.contentView, offset: .standard)
        self.label.centerOnX()
        
        self.personView.squaredSize = self.contentView.height
        self.personView.centerOnX()
        self.personView.pin(.top)
    }

    func configure(with item: String) {
        // TODO: Configure the video view.
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

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let memberCellAttributes = layoutAttributes as? MemberCellLayoutAttributes else { return }

        self.contentView.alpha = memberCellAttributes.alpha 
        self.videoView.shouldPlay = memberCellAttributes.isCentered
    }
}
