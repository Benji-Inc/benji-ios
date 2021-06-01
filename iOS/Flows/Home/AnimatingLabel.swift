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

            UIView.transition(with: self,
                              duration: Theme.animationDuration,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                guard let `self` = self else { return }
                                self.alpha = 1.0
                                self.text = localized(text)
                                self.layoutNow()
                              }, completion: nil)
        }
    }

    init() {
        super.init(frame: .zero, font: .small, textColor: .background4)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
