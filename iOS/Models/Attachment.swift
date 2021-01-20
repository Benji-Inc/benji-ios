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
    var mediaItem: MediaItem?
    var audioItem: AudioItem?

    var messageKind: MessageKind? {

        switch self.asset.mediaType {
        case .unknown:
            return nil
        case .image:
            if let item = self.mediaItem {
                return .photo(item)
            } else {
                return nil
            }
        case .video:
            if let item = self.mediaItem {
                return .video(item)
            } else {
                return nil
            }
        case .audio:
            if let item = self.audioItem {
                return .audio(item)
            } else {
                return nil
            }
        @unknown default:
            return nil
        }
    }

    init(with asset: PHAsset, info: [UIImagePickerController.InfoKey : Any]? = nil) {

        self.asset = asset

        if let info = info {
            switch asset.mediaType {
            case .image:
                self.mediaItem = PhotoAttachment(with: info)
            case .video:
                self.mediaItem = VideoAttachment(with: info)
            case .audio:
                self.audioItem = AudioAttachment(with: info)
            default:
                break
            }
        }
    }

    static func == (lhs: Attachement, rhs: Attachement) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class AttachmentItem {

    let info: [UIImagePickerController.InfoKey : Any]

    init(with info: [UIImagePickerController.InfoKey : Any]) {
        self.info = info
    }
}

class AudioAttachment: AttachmentItem, AudioItem {

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

class VideoAttachment: AttachmentItem, MediaItem {
    var url: URL?

    var image: UIImage?

    var size: CGSize {
        return .zero
    }

    var fileName: String {
        return String()
    }

    var type: MediaType {
        return .video
    }

    var data: Data?

}

class PhotoAttachment: AttachmentItem, MediaItem {

    var url: URL?

    var image: UIImage? {
        return self.info[.originalImage] as? UIImage
    }

    var size: CGSize {
        return .zero
    }

    var fileName: String {
        return String()
    }

    var type: MediaType {
        return .photo
    }

    var data: Data?
}
