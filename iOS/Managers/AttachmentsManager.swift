//
//  MediaManager.swift
//  Ours
//
//  Created by Benji Dodgson on 1/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos
import Combine

class PhotoRequestOptions: PHImageRequestOptions {

    override init() {
        super.init()
        self.deliveryMode = .highQualityFormat
        self.resizeMode = .exact
        self.isSynchronous = false
        self.isNetworkAccessAllowed = true
    }
}

class AttachmentsManager {

    static let shared = AttachmentsManager()
    private var cancellables = Set<AnyCancellable>()
    private let imageManager = PHImageManager()

    private(set) var attachments: [Attachment] = []

    var isAuthorized: Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        switch (status) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return false
        default:
            return false 
        }
    }

    func requestAttachements() -> Future<Void, Error> {
        return Future { promise in
            if self.isAuthorized {
                self.fetchAttachments()
                promise(.success(()))
            } else {
                self.requestAuthorization()
                    .mainSink { (result) in
                        switch result {
                        case .success():
                            self.fetchAttachments()
                            promise(.success(()))
                        case .error(let error):
                            promise(.failure(error))
                        }
                    }.store(in: &self.cancellables)
            }
        }
    }

    func getMessageKind(for attachment: Attachment, body: String) -> Future<MessageKind, Error> {
        return Future { promise in

            switch attachment.asset.mediaType {
            case .unknown:
                promise(.failure(ClientError.message(detail: "Unknown asset type.")))
            case .image:
                self.imageManager.requestImageDataAndOrientation(for: attachment.asset, options: PhotoRequestOptions()) { (data, type, orientation, info) in
                    let item = PhotoAttachment(url: nil, _data: data, info: info)
                    promise(.success(.photo(photo: item, body: body)))
                }
            case .video:
                promise(.failure(ClientError.message(detail: "Video not supported.")))
            case .audio:
                promise(.failure(ClientError.message(detail: "Audio not supported")))
            @unknown default:
                break
            }
        }
    }

    func getImage(for attachment: Attachment,
                  contentMode: PHImageContentMode = .aspectFill,
                  size: CGSize) -> Future<(UIImage, [AnyHashable: Any]?), Error> {

        return Future { promise in
            let options = PhotoRequestOptions()

            self.imageManager.requestImage(for: attachment.asset,
                                           targetSize: size,
                                           contentMode: contentMode,
                                           options: options) { (image, info) in
                if let img = image {
                    promise(.success((img, info)))
                } else {
                    promise(.failure(ClientError.message(detail: "Failed to retrieve image")))
                }
            }
        }
    }

    private func requestAuthorization() -> Future<Void, Error> {
        return Future { promise in
            PHPhotoLibrary.requestAuthorization({ (status) in
                switch status {
                case .authorized, .limited:
                    promise(.success(()))
                default:
                    promise(.failure(ClientError.message(detail: "Failed to authorize")))
                }
            })
        }
    }

    private func fetchAttachments() {
        let photosOptions = PHFetchOptions()
        photosOptions.fetchLimit = 20
        photosOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                              PHAssetMediaType.image.rawValue)
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: photosOptions)

        var attachments: [Attachment] = []

        var assets: [PHAsset] = []

        for index in 0...result.count - 1 {
            let asset = result.object(at: index)
            assets.append(asset)
            let attachement = Attachment(asset: asset)
            attachments.append(attachement)
        }

        self.attachments = attachments
    }
}
