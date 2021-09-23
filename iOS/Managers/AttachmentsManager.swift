//
//  MediaManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit
import Photos

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
    private let manager = PHImageManager()

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

    func requestAttachements() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            if self.isAuthorized {
                self.fetchAttachments()
                continuation.resume(returning: ())
            } else {
                Task {
                    do {
                        try await self.requestAuthorization()
                        self.fetchAttachments()
                        continuation.resume(returning: ())
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }


    func getMessageKind(for attachment: Attachment, body: String) async throws -> MessageKind {
        let messageKind: MessageKind = try await withCheckedThrowingContinuation { continuation in
            switch attachment.asset.mediaType {
            case .unknown:
                continuation.resume(throwing: ClientError.message(detail: "Unknown asset type."))
            case .image:
                self.manager.requestImageDataAndOrientation(for: attachment.asset,
                                                               options: PhotoRequestOptions())
                { (data, type, orientation, info) in
                    let item = PhotoAttachment(url: nil, _data: data, info: info)
                    continuation.resume(returning: .photo(photo: item, body: body))
                }
            case .video:
                continuation.resume(throwing: ClientError.message(detail: "Video not supported."))
            case .audio:
                continuation.resume(throwing: ClientError.message(detail: "Audio not supported"))
            @unknown default:
                continuation.resume(throwing: ClientError.message(detail: "Unknown asset type."))
            }
        }

        return messageKind
    }

    func getImage(for attachment: Attachment,
                  contentMode: PHImageContentMode = .aspectFill,
                  size: CGSize) async throws -> (UIImage, [AnyHashable: Any]?) {

        let result: (UIImage, [AnyHashable: Any]?) = try await withCheckedThrowingContinuation { continuation in
            let options = PhotoRequestOptions()

            self.manager.requestImage(for: attachment.asset,
                                           targetSize: size,
                                           contentMode: contentMode,
                                           options: options) { (image, info) in
                if let img = image {
                    continuation.resume(returning: (img, info))
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "Failed to retrieve image"))
                }
            }
        }

        return result
    }

    func getVideoAsset(for attachment: Attachment) async -> AVAsset? {
        let asset: AVAsset? = await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .fastFormat
            self.manager.requestAVAsset(forVideo: attachment.asset, options: options) { asset, audioMix, info in
                continuation.resume(returning: asset)
            }
        }
        return asset
    }

    private func requestAuthorization() async throws {
         return try await withCheckedThrowingContinuation { continuation in
             PHPhotoLibrary.requestAuthorization({ (status) in
                 switch status {
                 case .authorized, .limited:
                     continuation.resume(returning: ())
                 default:
                     continuation.resume(throwing: ClientError.message(detail: "Failed to authorize"))
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
