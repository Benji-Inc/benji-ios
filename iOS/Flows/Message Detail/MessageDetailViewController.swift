//
//  MessageDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDetailViewController: ViewController {

    private let messageView = MessageContentView()

    let message: Messageable

    init(message: Messageable) {
        self.message = message

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
            sheet.detents = [.large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }

        self.view.addSubview(self.messageView)
        self.messageView.configure(with: self.message)
        self.messageView.configureBackground(color: .blue,
                                             textColor: .red,
                                             brightness: 1,
                                             focusAmount: 1,
                                             showBubbleTail: false,
                                             tailOrientation: .down)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let horizontalMargins = Theme.ContentOffset.long.value.doubled
        let textViewSize = self.messageView.textView.getSize(with: .expanded,
                                                             width: self.view.width - horizontalMargins)
        self.messageView.size = textViewSize
        self.messageView.pin(.top, offset: .standard)
        self.messageView.centerOnX()
    }
}
