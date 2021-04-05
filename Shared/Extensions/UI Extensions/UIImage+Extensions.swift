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

    func fixedOrientation() -> UIImage? {

        guard imageOrientation != UIImage.Orientation.up else {
            //This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }

        guard let cgImage = self.cgImage else {
            //CGImage is not available
            return nil
        }

        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil //Not able to create CGContext
        }

        var transform: CGAffineTransform = CGAffineTransform.identity

        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case .left:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            break
        case .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
            break
        case .right:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            break
        case .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
            break
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }

        //Flip image one more time if needed to, this is to prevent flipped image
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: self.size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: self.size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            break 
        }

        ctx.concatenate(transform)

        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }

        guard let newCGImage = ctx.makeImage() else { return nil }
        let image = UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
        return image
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
}
#endif
