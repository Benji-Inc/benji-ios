//
//  InputActivityBar.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/8/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class InputActivityBar: View {

    static let height: CGFloat = 28
    private let label = Label(font: .small, textColor: .background4)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)
        self.addSubview(self.label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width - Theme.contentOffset)
        self.label.centerOnY()
        self.label.pin(.left, padding: 6)
    }

    func update(text: Localized, with hightlightedWords: [String] = []) {
        self.label.setText(text)
        hightlightedWords.forEach { highlight in
            self.label.add(attributes: [.font: FontType.smallBold.font], to: highlight)
        }
        self.layoutNow()
    }
}
