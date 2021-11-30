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

struct HightlightedPhrase {
    var text: Localized
    var highlightedWords: [Localized]
}

class DisclosureModalViewController: ViewController {

    private let blurView = BlurView()
    let titleLabel = Label(font: .display)
    let descriptionLabel = Label(font: .regular)
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        let maxWidth = self.view.width - Theme.contentOffset.doubled

        self.titleLabel.setSize(withWidth: maxWidth)
        self.titleLabel.centerOnX()
        self.titleLabel.pinToSafeArea(.top, offset: .xtraLong)

        self.descriptionLabel.setSize(withWidth: maxWidth)
        self.descriptionLabel.centerOnX()
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .standard)

        let contentHeight = self.view.height - (self.descriptionLabel.bottom + Theme.contentOffset) - self.view.safeAreaInsets.bottom
        self.contentView.size = CGSize(width: maxWidth, height: contentHeight)
        self.contentView.match(.top, to: .bottom, of: self.descriptionLabel, offset: .standard)
        self.contentView.centerOnX()
    }

    func updateDescription(with phrase: HightlightedPhrase) {
        self.descriptionLabel.setText(phrase.text)
        phrase.highlightedWords.forEach { highlight in
            self.descriptionLabel.add(attributes: [.font: FontType.regularBold.font], to: localized(highlight))
        }
        self.view.layoutNow()
    }
}
