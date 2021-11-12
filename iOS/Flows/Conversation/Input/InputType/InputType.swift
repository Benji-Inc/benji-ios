//
//  InputType.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum InputType {

    case photo
    case video
    case keyboard
    case calendar
    case jibs
    case confirmation

    var image: UIImage? {
        switch self {
        case .photo:
            return UIImage(systemName: "photo")
        case .video:
            return UIImage(systemName: "video")
        case .keyboard:
            return UIImage(systemName: "abc")
        case .calendar:
            return UIImage(systemName: "calendar")
        case .jibs:
            return UIImage(systemName: "bitcoinsign.circle")
        case .confirmation:
            return nil
        }
    }
}
