//
//  UIImage+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 2/4/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import AVFoundation

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

    var previewData: Data? {
        return self.jpegData(compressionQuality: 0.1)
    }

    enum HEICError: Error {
        case heicNotSupported
        case cgImageMissing
        case couldNotFinalize
    }

    func heicData(compressionQuality: CGFloat) throws -> Data {
        let data = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(data,
                                                                      AVFileType.heic as CFString,
                                                                      1,
                                                                      nil) else {
            throw HEICError.heicNotSupported
        }

        guard let cgImage = self.cgImage else { throw HEICError.cgImageMissing }

        let options: NSDictionary = [kCGImageDestinationLossyCompressionQuality: compressionQuality]

        CGImageDestinationAddImage(imageDestination, cgImage, options)

        guard CGImageDestinationFinalize(imageDestination) else {  throw HEICError.couldNotFinalize }

        return data as Data
    }
}

extension UIImage: ImageDisplayable {

    var image: UIImage? {
        return self
    }
}

#warning("Remove")
extension Data {
    var prettySize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(count))
    }
}
