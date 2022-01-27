//
//  InitialsCircleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

class InitialsCircleView: BaseView {
    
    let label = ThemeLabel(font: .display)

    lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = ThemeColor.D6.color.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset = .zero
        layer.shadowRadius = 6
        layer.fillColor = ThemeColor.B3.color.cgColor
        layer.borderColor = ThemeColor.D6.color.cgColor
        layer.strokeColor = ThemeColor.D6.color.cgColor
        layer.lineWidth = 2
        return layer
    }()

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false
        
        self.layer.insertSublayer(self.circleLayer, at: 0)
        
        self.addSubview(self.label)
    }
    
    func configure(with contact: CNContact) {
        self.label.setText(contact.initials)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
        
        self.circleLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.circleLayer.shadowPath = UIBezierPath(ovalIn: self.bounds).cgPath
    }
}
