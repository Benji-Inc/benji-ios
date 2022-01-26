//
//  CircleViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleViewController: ViewController {
    
    let label = ThemeLabel(font: .regularBold)
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.label)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.label.centerOnXAndY()
    }
    
}
