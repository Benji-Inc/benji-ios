//
//  DisclosureModalViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI
import TMROLocalization

class DisclosureModalViewController: ViewController {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let titleLabel = Label(font: .display)
    private let descriptionLabel = Label(font: .medium)
    let contentView = View()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)
        self.view.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .center
        self.view.addSubview(self.descriptionLabel)
        self.descriptionLabel.textAlignment = .center
        
        self.view.addSubview(self.contentView)

        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        self.titleLabel.setText(Lorem.name())
        let paragraph = "This is a paragraph about something super important that must be stated in a timely manner."

        self.updateDescription(text: paragraph, with: ["timely", "important"])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        let maxWidth = self.view.width - Theme.contentOffset.doubled

        self.titleLabel.setSize(withWidth: maxWidth)
        self.titleLabel.centerOnX()
        self.titleLabel.pinToSafeArea(.top, padding: Theme.contentOffset)

        self.descriptionLabel.setSize(withWidth: maxWidth)
        self.descriptionLabel.centerOnX()
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: Theme.contentOffset)

        let contentHeight = self.view.height - (self.descriptionLabel.bottom + Theme.contentOffset) - self.view.safeAreaInsets.bottom
        self.contentView.size = CGSize(width: maxWidth, height: contentHeight)
        self.contentView.match(.top, to: .bottom, of: self.descriptionLabel, offset: Theme.contentOffset)
        self.contentView.centerOnX()
    }

    func updateDescription(text: Localized, with hightlightedWords: [String] = []) {
        self.descriptionLabel.setText(text)
        hightlightedWords.forEach { highlight in
            self.descriptionLabel.add(attributes: [.font: FontType.mediumBold.font], to: highlight)
        }
        self.view.layoutNow()
    }
}
