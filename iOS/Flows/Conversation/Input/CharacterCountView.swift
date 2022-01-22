//
//  CharacterCountView.swift
//  Benji
//
//  Created by Benji Dodgson on 1/24/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CharacterCountView: BaseView {

    let label = ThemeLabel(font: .small)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.label.textAlignment = .right
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.expandToSuperviewSize()
    }

    func update(with count: Int, max: Int) {
        if count >= max {
            self.isHidden = false
            self.label.setText(self.getText(from: count, max: max))
        } else if count >= max - 20 {
            self.isHidden = false
            self.label.setText(self.getText(from: count, max: max))
        } else {
            self.isHidden = true
        }
    }

    private func getText(from count: Int, max: Int) -> String {
        return String("\(String(count))/\(String(max))")
    }
}
