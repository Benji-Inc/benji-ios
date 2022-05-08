//
//  PhotoAttachment.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos

struct PhotoAttachment: MediaItem {
    
    var url: URL?
    var previewURL: URL?

    private(set) var image: UIImage?

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
        didSet {
            self.convertDataIntoImage()
        }
    }

    var info: [AnyHashable: Any]?

    init(url: URL?,
         previewURL: URL?,
         data: Data?,
         info: [AnyHashable : Any]?) {
        
        self.url = url
        self.previewURL = previewURL
        self.data = data
        self.info  = info

        self.convertDataIntoImage()
    }

    mutating private func convertDataIntoImage() {
        guard let data = self.data else {
            self.image = nil
            return
        }

        self.image = UIImage(data: data)
    }
}
