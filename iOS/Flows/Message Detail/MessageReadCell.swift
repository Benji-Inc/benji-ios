//
//  MessageReadCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct ReadViewModel: Hashable {
    var authorId: String?
    var createdAt: Date?
}

class MessageReadCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = ReadViewModel
    
    var currentItem: ReadViewModel?
    
    let personView = BorderedPersonView()
    let label = ThemeLabel(font: .xtraSmall)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.personView)
        
        self.personView.contextCueView.scale = .small
        
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.alpha = 0.25
        
        self.subscribeToUpdates()
    }
    
    /// A reference to a task for configuring the cell.
    private var configurationTask: Task<Void, Never>?

    func configure(with item: ReadViewModel) {
        self.configurationTask?.cancel()
        
        guard let authorId = item.authorId else {
            self.personView.isVisible = false
            return
        }
        
        self.personView.isVisible = true 

        self.configurationTask = Task {
            guard let person = await PeopleStore.shared.getPerson(withPersonId: authorId) else { return }

            guard !Task.isCancelled else { return }

            self.personView.set(person: person)
            let dateString = item.createdAt?.getTimeAgoString()
            self.label.setText(dateString)
            
            self.setNeedsLayout()
            
            self.subscribeToUpdates()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnX()
        self.label.pin(.bottom)
        
        self.personView.squaredSize = self.contentView.height * 0.6
        self.personView.centerOnX()
        self.personView.match(.bottom, to: .top, of: self.label, offset: .negative(.short))
    }
    
    private func subscribeToUpdates() {
        // Make sure that the person's focus status up to date.
        PeopleStore.shared.$personUpdated.filter { [unowned self] updatedPerson in
            self.currentItem?.authorId == updatedPerson?.personId
        }.mainSink { [unowned self] updatedPerson in
            self.personView.set(person: updatedPerson)
        }.store(in: &self.cancellables)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.configurationTask?.cancel()
        self.personView.set(person: nil)
    }
}

