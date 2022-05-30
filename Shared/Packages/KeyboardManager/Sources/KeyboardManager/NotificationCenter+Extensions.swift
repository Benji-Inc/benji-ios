//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation
import UIKit

internal extension NotificationCenter.Publisher.Output {

    var keyboardEndFrame: CGRect {
        let rect = self.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        return rect
    }
}
