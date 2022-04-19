//
//  FaceDetectionViewController+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 1/18/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import Vision
import UIKit
import MetalKit

extension FaceDetectionViewController {

    func setupMetal() {
        self.metalDevice = MTLCreateSystemDefaultDevice()
        self.metalCommandQueue = self.metalDevice.makeCommandQueue()

        self.cameraView.device = self.metalDevice
        self.cameraView.isPaused = true
        self.cameraView.enableSetNeedsDisplay = false
        self.cameraView.delegate = self
        self.cameraView.framebufferOnly = false
    }

    func setupCoreImage() {
        self.ciContext = CIContext(mtlDevice: self.metalDevice)
    }

    // MARK: - Process Results

    // Performs the blend operation.
    func blend(original framePixelBuffer: CVPixelBuffer,
                       mask maskPixelBuffer: CVPixelBuffer) {

        let color = ThemeColor.B0.ciColor
        
        // Create CIImage objects for the video frame and the segmentation mask.
        let originalImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(self.orientation)
        var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        // Scale the mask image to fit the bounds of the video frame.
        let scaleX = originalImage.extent.width / maskImage.extent.width
        let scaleY = originalImage.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

        let solidColor = CIImage(color: color).cropped(to: maskImage.extent)

        // List of all filters: https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(originalImage, forKey: "inputImage")

        guard let bwImage = filter?.outputImage else { return }

        // Blend the original, background, and mask images.
        let blendFilter = CIFilter.blendWithRedMask()
        blendFilter.inputImage = bwImage
        blendFilter.backgroundImage = solidColor
        blendFilter.maskImage = maskImage

        // Set the new, blended image as current.
        self.currentCIImage = blendFilter.outputImage?.oriented(.leftMirrored)
    }
}

extension FaceDetectionViewController: MTKViewDelegate {

    func draw(in view: MTKView) {
        // grab command buffer so we can encode instructions to GPU
        guard let commandBuffer = self.metalCommandQueue.makeCommandBuffer() else {
            return
        }

        // grab image
        guard let ciImage = self.currentCIImage else {
            return
        }

        // ensure drawable is free and not tied in the preivous drawing cycle
        guard let currentDrawable = view.currentDrawable else {
            return
        }
        
        // make sure the image is full screen
        let drawSize = self.cameraView.drawableSize
        var scaleX = drawSize.width / ciImage.extent.width
        var scaleY = drawSize.height / ciImage.extent.height
        
        if scaleX > scaleY {
            scaleY = scaleX
        } else {
            scaleX = scaleY
        }

        let newImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        //render into the metal texture
        self.ciContext.render(newImage,
                              to: currentDrawable.texture,
                              commandBuffer: commandBuffer,
                              bounds: newImage.extent,
                              colorSpace: CGColorSpaceCreateDeviceRGB())

        // register drawwable to command buffer
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Delegate method not implemented.
    }
}
