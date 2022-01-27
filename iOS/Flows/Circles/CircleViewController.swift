//
//  CircleViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleViewController: ViewController {
    
    let backgroundGradient = BackgroundGradientView()
    let label = ThemeLabel(font: .regular)
    let remainingLabel = ThemeLabel(font: .small)
    let circleView = CircleView()
    
    override func loadView() {
        self.view = self.backgroundGradient
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.label)
        self.label.setText("Add people by tapping on any circle.")
        
        self.view.addSubview(self.remainingLabel)
        self.remainingLabel.setText("7 remaining")
        self.remainingLabel.alpha = 0.6
        
        self.view.addSubview(self.circleView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.label.centerOnXAndY()
        
        self.remainingLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.remainingLabel.centerOnX()
        self.remainingLabel.match(.top, to: .bottom, of: self.label, offset: .standard)
        
        self.circleView.squaredSize = 100
        self.circleView.pin(.top, offset: .xtraLong)
        self.circleView.centerOnX()
    }
}
