//
//  UIImage+MediaItem.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/2/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

#if !APPCLIP && !NOTIFICATION && !NOTIFICATION_SERVICE
// Code you don't want to use in your App Clip.
extension UIImage: MediaItem {

    var url: URL? {
        return nil
    }

    var previewURL: URL? {
        return nil
    }

    var fileName: String {
        return ""
    }

    var type: MediaType {
        .photo
    }

    var data: Data? {
        return self.jpegData(compressionQuality: 30.0)
    }
}
#endif
