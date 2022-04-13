//
//  WaitlistViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery
import ScrollCounter

class WaitlistViewController: ViewController {
        
    private let titleLabel = ThemeLabel(font: .mediumBold)
    private let bodyLabel = ThemeLabel(font: .regular)
    private let currentPositionLabel = ThemeLabel(font: .regular)
    private let counter = NumberScrollCounter(value: 0,
                                              scrollDuration: Theme.animationDurationSlow,
                                              decimalPlaces: 0,
                                              prefix: "",
                                              suffix: nil,
                                              seperator: "",
                                              seperatorSpacing: 0,
                                              font: FontType.small.font,
                                              textColor: ThemeColor.T1.color,
                                              animateInitialValue: true,
                                              gradientColor: nil,
                                              gradientStop: nil)
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.set(backgroundColor: .B0)
        self.view.addSubview(self.counter)
    }
}

extension WaitlistViewController: TransitionableViewController {
    var receivingPresentationType: TransitionType {
        return .fade
    }
}
