//
//  Attachment.swift
//  Ours
//
//  Created by Benji Dodgson on 1/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos

struct Attachment: ManageableCellItem, Hashable {

    var id: String {
        return self.asset.localIdentifier
    }

    let asset: PHAsset
    let info: [UIImagePickerController.InfoKey : Any]?

    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
