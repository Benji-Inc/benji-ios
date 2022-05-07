//
//  VideoAttachment.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/7/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos

struct VideoAttachment: MediaItem {

    var url: URL?

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
        return .video
    }

    var data: Data? {
        didSet {
            self.convertDataIntoVideo()
        }
    }

    var info: [AnyHashable: Any]?

    init(url: URL?, data: Data?, info: [AnyHashable : Any]?) {
        self.url = url
        self.data = data
        self.info  = info

        self.convertDataIntoVideo()
    }

    mutating private func convertDataIntoVideo() {
        self.image = self.getVideoSnapshot()
    }
    
    private func getVideoSnapshot() -> UIImage? {
        guard self.image.isNil, let url = url else {
            return nil
        }

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let timestamp = CMTime(seconds: 0.5, preferredTimescale: 60)

        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        }
        catch {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
}


