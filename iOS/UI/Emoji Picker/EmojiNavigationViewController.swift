//
//  EmojiNavigationViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmojiNavigationViewController: NavigationController {
    
    let emojiVC: EmojiPickerViewController
    
    init(with emojiVC: EmojiPickerViewController) {
        self.emojiVC = emojiVC
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
                
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
                
        self.setViewControllers([self.emojiVC], animated: false)
    }
}
