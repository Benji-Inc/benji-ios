//
//  CharacterCountView.swift
//  Benji
//
//  Created by Benji Dodgson on 1/24/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CharacterCountView: View {

    let label = newLabel(font: .small)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.label.textAlignment = .center
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.expandToSuperviewSize()
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
    }

    func udpate(with count: Int, max: Int) {
        if count >= max {
            self.isHidden = false
            self.label.setText(self.getText(from: count, max: max))
            self.label.setTextColor(.red)
        } else if count >= max - 20 {
            self.isHidden = false
            self.label.setText(self.getText(from: count, max: max))
            self.label.setTextColor(.orange)
        } else {
            self.isHidden = true
        }
    }

    private func getText(from count: Int, max: Int) -> String {
        return String("\(String(count))/\(String(max))")
    }
}
