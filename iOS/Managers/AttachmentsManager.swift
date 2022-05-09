//
//  MediaManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit
import Photos

struct ImageRequestResult {
    var data: Data?
    var type: String?
    var orientation: CGImagePropertyOrientation
    var info: [AnyHashable: Any]?
}


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
    
    func requestAttachments() async {
        return await withCheckedContinuation({ continuation in
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
                        continuation.resume(returning: ())
                    }
                }
            }
        })
    }
    
    func getMessageKind(for info: [UIImagePickerController.InfoKey : Any],
                        body: String) async throws -> MessageKind {

        return try await withCheckedThrowingContinuation { continuation in
            guard let mediaType = info[.mediaType] as? String else {
                continuation.resume(throwing: ClientError.message(detail: "Unknown asset type."))
                return
            }
            
            switch mediaType {
            case "public.image":
                do {
                    let image = info[.editedImage] as? UIImage
                    if let data = image?.jpegData(compressionQuality: 1.0),
                       let previewData = image?.jpegData(compressionQuality: 0.5) {
                        
                        let url = try self.createTemporaryURL(for: data, fileExtension: "")
                        let previewURL = try self.createTemporaryURL(for: previewData, fileExtension: "preview")
                        let item = PhotoAttachment(url: url,
                                                   previewURL: previewURL,
                                                   data: data,
                                                   info: info)
                        
                        continuation.resume(returning: .photo(photo: item, body: body))
                    } else {
                        continuation.resume(throwing: ClientError.message(detail: "Error preparing image for delivery"))
                    }
                } catch  {
                    logError(error)
                    continuation.resume(throwing: error)
                }
            case "public.movie":
                do {
                    if let mediaURL = info[.mediaURL] as? URL {
                        let videoData = try Data(contentsOf: mediaURL, options: .mappedIfSafe)
                        let url = try self.createTemporaryURL(for: videoData, fileExtension: "mov")
                        let previewData = try self.createVideoSnapshotPreviewData(from: mediaURL)
                        let previewURL = try self.createTemporaryURL(for: previewData, fileExtension: "")

                        let item = VideoAttachment(url: url,
                                                   previewURL: previewURL,
                                                   previewData: previewData,
                                                   data: videoData,
                                                   info: info)
                        continuation.resume(returning: .video(video: item, body: body))
                    } else {
                        continuation.resume(throwing: ClientError.apiError(detail: "Error preparing video for delivery"))
                    }
                } catch  {
                    logError(error)
                    continuation.resume(throwing: error)
                }
            default:
                continuation.resume(throwing: ClientError.message(detail: "Unknown asset type."))
            }
        }
    }

    func createTemporaryURL(for data: Data, fileExtension: String) throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(),
                      isDirectory: true).appendingPathComponent(UUID().uuidString+".\(fileExtension)")
        try data.write(to: url, options: .atomic)
        return url
    }
    
    func getMessageKind(for attachments: [Attachment], body: String) async -> MessageKind? {
        return await withCheckedContinuation { continuation in
            
            // If there is only one attachment
            if attachments.count == 1, let first = attachments.first {
                Task { () -> MessageKind? in
                    guard let item = await self.getMediaItem(for: first) else { return nil }
                    
                    switch first.asset.mediaType {
                    case .image:
                        continuation.resume(returning: .photo(photo: item, body: body))
                    case .video:
                        continuation.resume(returning: .video(video: item, body: body))
                    case .audio:
                        continuation.resume(returning: nil)
                    default:
                        continuation.resume(returning: nil)
                    }
                    
                    return nil
                }

            // Or map all of them
            } else {
                Task {
                    let items: [MediaItem] = await attachments.asyncMap { [unowned self] attachment in
                        return await self.getMediaItem(for: attachment) ?? EmptyMediaItem(mediaType: .photo)
                    }

                    continuation.resume(returning: .media(items: items, body: body))
                }
            }
        }
    }
    
    private func getMediaItem(for attachment: Attachment) async -> MediaItem? {
        switch attachment.asset.mediaType {
        case .image:
            let result = await self.manager.requestImageData(for: attachment.asset, options: PhotoRequestOptions())
            
            let url = try? await self.getAssetURL(for: attachment.asset)
            let item = PhotoAttachment(url: url,
                                       previewURL: nil,
                                       data: result.data,
                                       info: result.info)
            return item
        case .video:
            if let url = try? await self.getAssetURL(for: attachment.asset),
               let previewData = try? self.createVideoSnapshotPreviewData(from: url) {
                
                let previewURL = try? self.createTemporaryURL(for: previewData, fileExtension: "")
                let item = VideoAttachment(url: url,
                                           previewURL: previewURL,
                                           previewData: previewData,
                                           data: nil,
                                           info: attachment.attributes)
                return item
            } else {
                return nil
            }
            
        case .audio:
            return nil
        default:
            return nil
        }
    }
    
    private func getAssetURL(for asset: PHAsset) async throws -> URL {
        return try await withCheckedThrowingContinuation({ continuation in
            if asset.mediaType == .image {
                let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
                options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                    return true
                }
                asset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
                    if let url = contentEditingInput?.fullSizeImageURL {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: ClientError.message(detail: "No URL for image"))
                    }
                })
            } else if asset.mediaType == .video {
                let options: PHVideoRequestOptions = PHVideoRequestOptions()
                options.version = .original
                self.manager.requestAVAsset(forVideo: asset, options: options, resultHandler: { (asset, audioMix, info) in
                    if let urlAsset = asset as? AVURLAsset {
                        let localVideoUrl = urlAsset.url
                        continuation.resume(returning: localVideoUrl)
                    } else {
                        continuation.resume(throwing: ClientError.message(detail: "No URL for Video"))
                    }
                })
            }
        })
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
    
    private func createVideoSnapshotPreviewData(from url: URL) throws -> Data {
                
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let timestamp = CMTime(seconds: 0.5, preferredTimescale: 60)

        let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
        return UIImage(cgImage: imageRef).jpegData(compressionQuality: 0.5) ?? Data()
    }
    
    private func fetchAttachments() {
        let options = PHFetchOptions()
        options.fetchLimit = 20
        let videoPredicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        let imagePredicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [videoPredicate, imagePredicate])
        options.predicate = predicate
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: options)
        
        var attachments: [Attachment] = []
        
        var assets: [PHAsset] = []
        
        for index in 0...result.count - 1 {
            let asset = result.object(at: index)
            assets.append(asset)
            let attachment = Attachment(asset: asset)
            attachments.append(attachment)
        }
        
        self.attachments = attachments
    }
}

extension PHImageManager {
    
    func requestImageData(for asset: PHAsset, options: PHImageRequestOptions?) async -> ImageRequestResult {
        return await withCheckedContinuation({ continuation in
            self.requestImageDataAndOrientation(for: asset, options: options) { data, type, orientation, info in
                continuation.resume(returning: ImageRequestResult(data: data, type: type, orientation: orientation, info: info))
            }
        })
    }
}
