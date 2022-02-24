//
//  MessageDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDetailViewController: ViewController {

    let messageView = MessageTextView()

    override func initializeViews() {
        super.initializeViews()

        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }

        self.view.addSubview(self.messageView)
        self.messageView.backgroundColor = .blue
        self.messageView.text = Lorem.paragraph()
        self.messageView.isEditable = true
        self.messageView.isScrollEnabled = true
        self.messageView.isSelectable = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.messageView.setSize(withMaxWidth: self.view.width - 60)
    }
}
