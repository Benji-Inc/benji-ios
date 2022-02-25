//
//  MessageDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

@MainActor
protocol MessageDetailViewControllerDelegate: AnyObject {
    func messageDetailViewController(_ controller: MessageDetailViewController,
                                     didSelectThreadFor message: Messageable)
}

class MessageDetailViewController: ViewController {

    let message: Messageable
    unowned let delegate: MessageDetailViewControllerDelegate

    private let textView = TextView(font: .regular, textColor: .T3)
    private let bubbleView = MessageBubbleView(orientation: .down, bubbleColor: ThemeColor.D1.color)
    private let backgroundView = BaseView()
    private let threadButton = ThemeButton()

    init(message: Messageable, delegate: MessageDetailViewControllerDelegate) {
        self.message = message
        self.delegate = delegate

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
            popoverPresentationController.backgroundColor = .red
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

        self.view.addSubview(self.threadButton)
        self.threadButton.set(style: .normal(color: .gray, text: "Open Thread"))
        self.threadButton.addAction(for: .touchUpInside) { [unowned self] in
            self.delegate.messageDetailViewController(self, didSelectThreadFor: self.message)
        }
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

        self.threadButton.width = 100
        self.threadButton.height = Theme.buttonHeight
        self.threadButton.pin(.bottom)
    }
}
