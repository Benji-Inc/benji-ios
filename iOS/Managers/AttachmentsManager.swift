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

private class PhotoRequestOptions: PHImageRequestOptions {

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

    func requestAttachements() -> Future<[Attachement], Error> {
        return Future { promise in
            if self.isAuthorized {
                promise(.success(self.fetchAttachments()))
            } else {
                self.requestAuthorization()
                    .mainSink { (result) in
                        switch result {
                        case .success():
                            promise(.success(self.fetchAttachments()))
                        case .error(let error):
                            promise(.failure(error))
                        }
                    }.store(in: &self.cancellables)
            }
        }
    }

    func loadImage(for attachment: Attachement, size: CGSize) -> Future<UIImage, Error> {
        return Future { promise in
            let options = PhotoRequestOptions()
            self.imageManager.requestImage(for: attachment.asset,
                                           targetSize: size,
                                           contentMode: .aspectFill,
                                           options: options) { (image, info) in
                if let img = image {
                    promise(.success(img))
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

    private func fetchAttachments() -> [Attachement] {
        let photosOptions = PHFetchOptions()
        photosOptions.fetchLimit = 20
        photosOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                              PHAssetMediaType.image.rawValue)
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: photosOptions)

        var attachments: [Attachement] = []

        var assets: [PHAsset] = []

        for index in 0...result.count - 1 {
            let asset = result.object(at: index)
            assets.append(asset)
            let attachement = Attachement(with: asset)
            attachments.append(attachement)
        }

        return attachments
    }
}
