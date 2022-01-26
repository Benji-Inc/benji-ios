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
    let label = ThemeLabel(font: .regularBold)
    let circleView = CircleView()
    
    override func loadView() {
        self.view = self.backgroundGradient
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.label)
        self.label.setText("This is some text")
        
        self.view.addSubview(self.circleView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.label.centerOnXAndY()
        
        self.circleView.squaredSize = 100
        self.circleView.pin(.top, offset: .xtraLong)
        self.circleView.centerOnX()
    }
}
