//
//  StackedPersonView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class StackedPersonView: BaseView {
    
    private let label = ThemeLabel(font: .small)
    private var peopleIds: [String] = []
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false
    }
    
    func configure(with people: [PersonType]) {
        let ids = people.compactMap { person in
            return person.personId
        }
        
        guard self.peopleIds != ids else { return }
        
        self.peopleIds = ids
        self.removeAllSubviews()
        
        for (index, person) in people.enumerated() {
            if index <= 2 {
                let view = BorderedPersonView()
                view.set(person: person)
                view.contextCueView.isVisible = false
                self.addSubview(view)
            }
        }
        
        if people.count > 3 {
            let remainder = people.count - 3
            self.label.setText("+\(remainder)")
            self.addSubview(self.label)
        }
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = 22
        
        var xOffset: CGFloat = 0
        var count: Int = 0
        self.subviews.forEach { view in
            if let personView = view as? BorderedPersonView {
                personView.pulseLayer.borderWidth = 1
                personView.shadowLayer.opacity = 0.0
                personView.frame = CGRect(x: xOffset,
                                          y: 0,
                                          width: self.height,
                                          height: self.height)
                xOffset += view.width + Theme.ContentOffset.short.value
                count += 1
            }
        }
        
        xOffset -= Theme.ContentOffset.short.value
         
        if count == 3 {
            self.label.setSize(withWidth: 30)
            xOffset += self.label.width + Theme.ContentOffset.short.value
            self.label.centerOnY()
            self.label.right = xOffset
        }
        
        self.width = xOffset
    }
}
