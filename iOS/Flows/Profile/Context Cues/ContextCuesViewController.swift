//
//  ContextCuesViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCuesViewController: ViewController {
    
    let label = ThemeLabel(font: .regular)
    let lineView = BaseView()
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .B2)
        self.lineView.alpha = 0.5
        
        self.label.textAlignment = .left
        self.view.addSubview(self.label)
        self.label.setText("Current Status")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.label.setSize(withWidth: self.view.width)
        self.label.pin(.left, offset: .screenPadding)
        self.label.pin(.top)
        
        self.lineView.expandToSuperviewWidth()
        self.lineView.height = 1
        self.lineView.centerOnXAndY()
    }
}
