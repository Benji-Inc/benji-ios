//
//  PhotoAttachment.swift
//  Ours
//
//  Created by Benji Dodgson on 1/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos

struct PhotoAttachment: MediaItem {

    var url: URL?

    var image: UIImage? {
        guard let data = self.data else { return nil }
        return UIImage(data: data)
    }

    var size: CGSize {
        guard let asset = self.info?[UIImagePickerController.InfoKey.phAsset] as? PHAsset else { return .zero }
        return CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
    }

    var fileName: String {
        guard let asset = self.info?[UIImagePickerController.InfoKey.phAsset] as? PHAsset else { return String() }
        return asset.localIdentifier
    }

    var type: MediaType {
        return .photo
    }

    var data: Data? {
        return self._data
    }

    var _data: Data?
    var info: [AnyHashable: Any]?
}
