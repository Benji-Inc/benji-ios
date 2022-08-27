//
//  ReactionsDetailViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Transitions

class ReactionsDetailViewController: ExpressionDetailViewController {
    
    let blurView = DarkBlurView()
    let button = ThemeButton()
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)
        
        self.view.addSubview(self.button)
        self.button.set(style: .custom(color: .white, textColor: .B0, text: "Add"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = MomentViewController.cornerRadius
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.blurView.expandToSuperviewSize()
        
        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        self.button.match(.bottom, to: .top, of: self.pageIndicator, offset: .negative(.long))
    }
}
