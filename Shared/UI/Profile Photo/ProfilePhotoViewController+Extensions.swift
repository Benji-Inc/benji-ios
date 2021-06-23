//
//  ProfileViewController+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 6/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import MetalKit
import AVFoundation

extension ProfilePhotoViewController {

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
}

extension ProfilePhotoViewController: MTKViewDelegate {
    
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
        let scaleX = drawSize.width / ciImage.extent.width
        let scaleY = drawSize.height / ciImage.extent.height

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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ProfilePhotoViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Grab the pixelbuffer frame from the camera output
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        self.processVideoFrame(pixelBuffer)
    }
}

