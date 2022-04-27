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

    func imageWith(maxSideLength: CGFloat) -> UIImage {
        let scale: CGFloat

        if self.size.width > self.size.height {
            scale = min(maxSideLength/self.size.width, 1)
        } else {
            scale = min(maxSideLength/self.size.height, 1)
        }

        let newSize = CGSize(width: scale * self.size.width,
                             height: scale * self.size.height)

        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }

        logDebug("original size \(Float(self.pngData()!.count)/1_000_000)")
        logDebug("shrunk size \(Float(image.withRenderingMode(self.renderingMode).pngData()!.count)/1_000_000)")
        logDebug("new dimensions are \(newSize)")
        return image.withRenderingMode(self.renderingMode)
    }

    func centerCroppedImage() -> UIImage {
        // Get the shortest side
        let sideLength = min(self.size.width, self.size.height)

        // Determines the x,y coordinate of a centered
        // sideLength by sideLength square
        let originalSize = self.size
        let xOffset = (originalSize.width - sideLength)/2
        let yOffset = (originalSize.height - sideLength)/2

        // The area of the image that we want to keep.
        let cropRect = CGRect(x: xOffset,
                              y: yOffset,
                              width: sideLength,
                              height: sideLength).integral

        // Center crop the image and covert back to a UIImage
        if let originalCGImage = self.cgImage {
            let croppedCGImage = originalCGImage.cropping(to: cropRect)!
            return UIImage(cgImage: croppedCGImage,
                           scale: self.imageRendererFormat.scale,
                           orientation: self.imageOrientation)
        } else if let originalCIImage = self.ciImage {
            let croppedCIImage = originalCIImage.cropped(to: cropRect)

            let context = CIContext()
            let croppedCGImage = context.createCGImage(croppedCIImage, from: croppedCIImage.extent)!
            return UIImage(cgImage: croppedCGImage,
                           scale: self.imageRendererFormat.scale,
                           orientation: self.imageOrientation)
        }

        return self
    }

    var previewPngData: Data? {
        return self.centerCroppedImage().imageWith(maxSideLength: 150).pngData()
    }
}

extension UIImage: ImageDisplayable {

    var image: UIImage? {
        return self
    }
}
