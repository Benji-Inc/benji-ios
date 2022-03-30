//
//  TypingIndicatorView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class TypingIndicatorView: BaseView {
    
    private let label = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.pin(.left)
        self.label.pin(.bottom)
    }
    
    func update(typers: [PersonType]) {
        var text = ""
        var names: [String] = []
        
        for (index, person) in typers.enumerated() {
            if index == 0 {
                text.append(person.givenName)
            } else {
                text.append(", \(person.givenName)")
            }
            
            names.append(person.givenName)
        }
        
        text.append(" is typing...")
        
        self.label.setText(text)
        names.forEach { highlight in
            self.label.add(attributes: [.font: FontType.smallBold.font], to: highlight)
        }
        
        self.layoutNow()
    }
}
