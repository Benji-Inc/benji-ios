//
//  BlurredViewControllerf.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class BlurredViewController: FullScreenViewController {
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
    }
}
