//
//  ContextCuesViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCuesViewController: ViewController {
    
    let lineView = BaseView()
    
    let tempView = BaseView()
    let label = ThemeLabel(font: .regular)
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .B2)
        self.lineView.alpha = 0.5
        
        self.view.addSubview(self.tempView)
        self.tempView.set(backgroundColor: .B0)
        self.tempView.layer.borderColor = ThemeColor.white.color.withAlphaComponent(0.3).cgColor
        self.tempView.layer.borderWidth = 1
        self.tempView.layer.cornerRadius = Theme.cornerRadius
        self.tempView.layer.masksToBounds = true
        
        self.view.addSubview(self.label)
        
        self.label.textAlignment = .center
        self.label.setText("Coming soon 😉")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.lineView.expandToSuperviewWidth()
        self.lineView.height = 1
        self.lineView.centerOnXAndY()
        
        self.label.setSize(withWidth: self.view.width)
        self.label.centerOnXAndY()
        
        self.tempView.expandToSuperviewHeight()
        self.tempView.width = self.label.width + Theme.ContentOffset.xtraLong.value.doubled
        self.tempView.centerOnXAndY()
    }
}
