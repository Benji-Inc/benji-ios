//
//  Attachment.swift
//  Ours
//
//  Created by Benji Dodgson on 1/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos

struct Attachement: ManageableCellItem, Hashable {

    var id: String {
        return self.asset.localIdentifier
    }

    let asset: PHAsset
    let info: [UIImagePickerController.InfoKey : Any]?

    static func == (lhs: Attachement, rhs: Attachement) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class AudioAttachment: AudioItem {

    var url: URL {
        return URL(string: "")!
    }

    var duration: Float {
        return 0.0
    }

    var size: CGSize {
        return .zero
    }
}

//class VideoAttachment: MediaItem {
//
//    var url: URL? {
//        return self.info[UIImagePickerController.InfoKey.mediaURL] as? URL
//    }
//
//    var image: UIImage? {
//        return self.info[UIImagePickerController.InfoKey.originalImage] as? UIImage
//    }
//
//    var size: CGSize {
//        guard let asset = self.info[UIImagePickerController.InfoKey.phAsset] as? PHAsset else { return .zero }
//        return CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
//    }
//
//    var fileName: String {
//        guard let asset = self.info[UIImagePickerController.InfoKey.phAsset] as? PHAsset else { return String() }
//        return asset.localIdentifier
//    }
//
//    var type: MediaType {
//        return .video
//    }
//
//    var data: Data? {
//        return nil // Not sure how to extract this
//    }
//}

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
