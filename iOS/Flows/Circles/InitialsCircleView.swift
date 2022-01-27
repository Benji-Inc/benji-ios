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
    
    lazy var shadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = ThemeColor.D6.color.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowOffset = .zero
        layer.shadowRadius = 10
        return layer
    }()

    lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = ThemeColor.B3.color.cgColor
        return layer
    }()
    
    lazy var borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.borderColor = ThemeColor.D6.color.cgColor
        layer.strokeColor = ThemeColor.D6.color.cgColor
        layer.borderWidth = 1.5
        return layer
    }()

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false
        
        self.layer.insertSublayer(self.shadowLayer, at: 0)
        self.layer.insertSublayer(self.circleLayer, at: 1)
        self.layer.insertSublayer(self.borderLayer, at: 2)
        
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
        
        self.shadowLayer.shadowPath = UIBezierPath(ovalIn: self.bounds).cgPath
        self.circleLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.borderLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
    }
}
