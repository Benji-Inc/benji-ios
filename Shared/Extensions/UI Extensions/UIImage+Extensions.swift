//
//  UIImage+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 2/4/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

extension UIImage {

    func grayscaleImage() -> UIImage? {
        let ciImage = CIImage(image: self)
        guard let grayscale = ciImage?.applyingFilter("CIColorControls",
                                                      parameters: [ kCIInputSaturationKey: 0.0 ]) else { return nil
        }
        
        return UIImage(ciImage: grayscale)
    }

    static func imageWithColor(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context!.setFillColor(color.cgColor)
        context!.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }

    func scaled(by scale: CGFloat) -> UIImage {
        let size = self.size.applying(CGAffineTransform(scaleX: scale, y: scale))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        draw(in: CGRect(origin: CGPoint.zero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return scaledImage
    }
}

extension UIImage: Avatar {

    var givenName: String {
        return "First"
    }

    var familyName: String {
        return "Last"
    }

    var handle: String {
        return String()
    }

    var image: UIImage? {
        return self
    }

    var userObjectID: String? {
        return nil
    }
}

#if !APPCLIP && !NOTIFICATION
// Code you don't want to use in your App Clip.
extension UIImage: MediaItem {

    var url: URL? {
        return nil
    }

    var fileName: String {
        return ""
    }

    var type: MediaType {
        .photo
    }

    var data: Data? {
        return self.jpegData(compressionQuality: 100.0)
    }

    var previewData: Data? {
        return self.jpegData(compressionQuality: 30.0)
    }
}
#endif
