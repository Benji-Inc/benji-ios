//
//  AnimatingLabel.swift
//  Ours
//
//  Created by Benji Dodgson on 3/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class AnimatingLabel: Label {

    var animatedText: Localized? {
        didSet {
            guard let text = self.animatedText else { return }

            if let attributedText = self.attributedText, !attributedText.string.isEmpty {
                if attributedText.string != localized(text) {
                    self.fade(toText: localized(text)) { [unowned self] in
                        self.layoutNow()
                    }
                }
            } else {
                self.setText(text)
                self.setTextColor(.white)
            }
        }
    }

    init() {
        super.init(frame: .zero, font: .regular, textColor: .white)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
