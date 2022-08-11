//
//  MomentsHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/11/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentsHeaderView: UICollectionReusableView {
    
    let sundayLabel = ThemeLabel(font: .smallBold)
    let mondayLabel = ThemeLabel(font: .smallBold)
    let tuesdayLabel = ThemeLabel(font: .smallBold)
    let wednesdayLabel = ThemeLabel(font: .smallBold)
    let thursdayLabel = ThemeLabel(font: .smallBold)
    let fridayLabel = ThemeLabel(font: .smallBold)
    let saturdayLabel = ThemeLabel(font: .smallBold)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        
        self.addSubview(self.sundayLabel)
        self.sundayLabel.textAlignment = .center
        self.sundayLabel.setText("SUN")
        
        self.addSubview(self.mondayLabel)
        self.mondayLabel.textAlignment = .center
        self.mondayLabel.setText("MON")
        
        self.addSubview(self.tuesdayLabel)
        self.tuesdayLabel.textAlignment = .center
        self.tuesdayLabel.setText("TUE")
        
        self.addSubview(self.wednesdayLabel)
        self.wednesdayLabel.textAlignment = .center
        self.wednesdayLabel.setText("WED")
        
        self.addSubview(self.thursdayLabel)
        self.thursdayLabel.textAlignment = .center
        self.thursdayLabel.setText("THU")
        
        self.addSubview(self.fridayLabel)
        self.fridayLabel.textAlignment = .center
        self.fridayLabel.setText("FRI")
        
        self.addSubview(self.saturdayLabel)
        self.saturdayLabel.textAlignment = .center
        self.saturdayLabel.setText("SAT")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let labelWidth = self.width / 7
        
        self.sundayLabel.setSize(withWidth: self.width)
        self.sundayLabel.width = labelWidth
        self.sundayLabel.pin(.bottom, offset: .short)
        self.sundayLabel.pin(.left)
        
        self.mondayLabel.setSize(withWidth: self.width)
        self.mondayLabel.width = labelWidth
        self.mondayLabel.pin(.bottom, offset: .short)
        self.mondayLabel.match(.left, to: .right, of: self.sundayLabel)
        
        self.tuesdayLabel.setSize(withWidth: self.width)
        self.tuesdayLabel.width = labelWidth
        self.tuesdayLabel.pin(.bottom, offset: .short)
        self.tuesdayLabel.match(.left, to: .right, of: self.mondayLabel)
        
        self.wednesdayLabel.setSize(withWidth: self.width)
        self.wednesdayLabel.width = labelWidth
        self.wednesdayLabel.pin(.bottom, offset: .short)
        self.wednesdayLabel.match(.left, to: .right, of: self.tuesdayLabel)
        
        self.thursdayLabel.setSize(withWidth: self.width)
        self.thursdayLabel.width = labelWidth
        self.thursdayLabel.pin(.bottom, offset: .short)
        self.thursdayLabel.match(.left, to: .right, of: self.wednesdayLabel)
        
        self.fridayLabel.setSize(withWidth: self.width)
        self.fridayLabel.width = labelWidth
        self.fridayLabel.pin(.bottom, offset: .short)
        self.fridayLabel.match(.left, to: .right, of: self.thursdayLabel)
        
        self.saturdayLabel.setSize(withWidth: self.width)
        self.saturdayLabel.width = labelWidth
        self.saturdayLabel.pin(.bottom, offset: .short)
        self.saturdayLabel.match(.left, to: .right, of: self.fridayLabel)
    }
}
