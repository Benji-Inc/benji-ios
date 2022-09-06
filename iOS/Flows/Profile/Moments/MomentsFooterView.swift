//
//  MomentsFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/11/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentsFooterView: UICollectionReusableView {
    
    let timeLabel = ThemeLabel(font: .small, textColor: .whiteWithAlpha)
    let button = ThemeButton()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        self.addSubview(self.timeLabel)
        self.timeLabel.setText("Last 14 Days")
        self.timeLabel.textAlignment = .center
        
        self.addSubview(self.button)
        self.button.set(style: .custom(color: .white, textColor: .B0, text: "View All"))
    }
    
    func animate() {
        self.timeLabel.alpha = 0.0
        self.button.alpha = 0.0

        Task.onMainActorAsync {
            await Task.sleep(seconds: 0.65)
            await UIView.awaitAnimation(with: .slow, animations: {
                self.timeLabel.alpha = 1.0
                self.button.alpha = 1.0
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.timeLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.width))
        self.timeLabel.centerOnX()
        self.timeLabel.pin(.top, offset: .xtraLong)
        
        self.button.setSize(with: self.width + Theme.ContentOffset.xtraLong.value.doubled)
        self.button.pin(.bottom)
        self.button.centerOnX()
    }
}
