//
//  CalendarHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CalendarHeaderView: UICollectionReusableView {
    
    let label = ThemeLabel(font: .mediumBold)
    let yearLabel = ThemeLabel(font: .medium)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        self.addSubview(self.label)
        self.addSubview(self.yearLabel)
    }
    
    func configure(with date: Date) {
        self.label.setText(Date.monthWithDate.string(from: date))
        self.yearLabel.setText(Date.yearWithDate.string(from: date))
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.pin(.left)
        self.label.pin(.bottom)
        
        self.yearLabel.setSize(withWidth: self.width)
        self.yearLabel.match(.bottom, to: .bottom, of: self.label)
        self.yearLabel.match(.left, to: .right, of: self.label, offset: .standard)
    }
    
    func animate() {
        self.subviews.forEach { view in
            view.alpha = 0
        }

        Task.onMainActorAsync {
            await Task.sleep(seconds: 0.15)
            await UIView.awaitAnimation(with: .slow, animations: {
                self.subviews.forEach { view in
                    view.alpha = 1.0
                }
            })
        }
    }
}
