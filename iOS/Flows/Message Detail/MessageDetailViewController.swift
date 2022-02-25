//
//  MessageDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDetailViewController: ViewController {

    let message: Messageable

    private let textView = TextView(font: .regular, textColor: .T3)
    private let bubbleView = MessageBubbleView(orientation: .down, bubbleColor: ThemeColor.D1.color)
    private let backgroundView = BaseView()

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
        if let popoverPresentationController = self.popoverPresentationController {
            let sheet = popoverPresentationController.adaptiveSheetPresentationController
            sheet.detents = [.medium()]
        }

        self.view.addSubview(self.bubbleView)
        self.bubbleView.tailLength = 0

        self.bubbleView.addSubview(self.textView)
        self.textView.text = self.message.kind.text
        self.textView.isEditable = false
        self.textView.isSelectable = true

        self.view.addSubview(self.backgroundView)
        self.backgroundView.set(backgroundColor: .B0)
        self.backgroundView.layer.cornerRadius = Theme.cornerRadius
        self.backgroundView.clipsToBounds = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let horizontalMargins = Theme.ContentOffset.screenPadding.value.doubled
        self.bubbleView.width = self.view.width - horizontalMargins

        self.textView.setSize(withMaxWidth: self.bubbleView.width - MessageContentView.textViewPadding)
        self.textView.pin(.top, offset: .long)
        self.textView.centerOnX()

        self.bubbleView.height = self.textView.height + Theme.ContentOffset.long.value.doubled
        self.bubbleView.centerOnXAndY()

        self.backgroundView.match(.top, to: .bottom, of: self.bubbleView, offset: .xtraLong)
        self.backgroundView.expandToSuperviewWidth()
        self.backgroundView.expand(.bottom)
    }
}
