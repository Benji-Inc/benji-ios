//
//  PhoneTextField.swift
//  Benji
//
//  Created by Benji Dodgson on 1/18/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PhoneNumberKit

class PhoneTextField: PhoneNumberTextField {
    
    override var defaultRegion: String {
        get {
            return "US"
        }
        set {}
    }
}
