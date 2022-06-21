//
//  StackedPersonView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class StackedPersonView: BaseView {
    
    var itemHeight: CGFloat = 22
    
    private let label = ThemeLabel(font: .small)
    private var peopleIds: [String] = []
    var max: Int = 3
    
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
            if index <= self.max - 1 {
                let view = BorderedPersonView()
                view.pulseLayer.lineWidth = 1
                view.pulseLayer.borderWidth = 1
                view.set(person: person)
                view.contextCueView.shouldStayHidden = true
                self.addSubview(view)
            }
        }
        
        if people.count > self.max {
            let remainder = people.count - self.max
            self.label.setText("+\(remainder)")
            self.addSubview(self.label)
        }
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = self.itemHeight
        
        var xOffset: CGFloat = 0
        var count: Int = 0
        self.subviews.forEach { view in
            if let personView = view as? BorderedPersonView {
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
         
        if count == self.max {
            self.label.setSize(withWidth: 30)
            xOffset += self.label.width + Theme.ContentOffset.short.value
            self.label.centerOnY()
            self.label.right = xOffset
        }
        
        self.width = xOffset
    }
}
