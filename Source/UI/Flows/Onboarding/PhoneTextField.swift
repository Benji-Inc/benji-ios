//
//  PhoneTextField.swift
//  Benji
//
//  Created by Benji Dodgson on 1/18/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PhoneNumberKit
import Lottie

class PhoneTextField: PhoneNumberTextField {
    
    override var defaultRegion: String {
        get { return "US" }
        set {}
    }

    let animationView = AnimationView(name: "loading")

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Make sure pod is updated to use "" vs " " in shouldChangeCharacter in order to have autocomplete work
        self.withPrefix = false
        self.textContentType = .telephoneNumber
        self.keyboardType = .numbersAndPunctuation
        
        self.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.pin(.right, padding: 10)
        self.animationView.centerOnY()
    }
}
