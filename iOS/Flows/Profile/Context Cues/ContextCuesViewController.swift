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
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .B2)
        self.lineView.alpha = 0.5
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.lineView.expandToSuperviewWidth()
        self.lineView.height = 1
        self.lineView.centerOnXAndY()
    }
}
