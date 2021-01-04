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

    override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // This allows for the case when a user autocompletes a phone number:
        if range == NSRange(location: 0, length: 0), string == "" {
            return true
        } else {
            return super.textField(textField,
                                   shouldChangeCharactersIn: range,
                                   replacementString: string)
        }
    }
}
