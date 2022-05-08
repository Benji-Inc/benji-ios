//
//  Attachment.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos

struct Attachment: Hashable {

    var id: String {
        return self.asset.localIdentifier
    }

    let asset: PHAsset

    var attributes: [String: Any] {
        return ["mediaType": self.asset.mediaType.rawValue,
                "duration": Int(self.asset.duration),
                "pixelWidth": self.asset.pixelWidth,
                "pixelHeight": self.asset.pixelHeight,
                "creationDate": self.asset.creationDate as Any,
                "location": ["latitude": self.asset.location?.coordinate.latitude,
                             "longitude": self.asset.location?.coordinate.longitude]]
    }

    var duration: Int {
        guard let value = self.attributes["duration"] as? Int else { return 5 }
        return clamp(value, min: 5)
    }
    
    var isVideo: Bool {
        guard let type = PHAssetMediaType.init(rawValue: self.mediaType), type == .video else { return false }
        return true 
    }

    var mediaType: Int {
        return self.attributes["mediaType"] as? Int ?? 0
    }

    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
