//
//  LivePhotoViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import Combine
import UIKit

class PhotoCaptureSession {

    weak var avCaptureDelegate: (AVCaptureVideoDataOutputSampleBufferDelegate & AVCapturePhotoCaptureDelegate)?

    lazy var session = AVCaptureSession()
    private var capturePhotoOutput: AVCapturePhotoOutput!

    private let dataOutputQueue = DispatchQueue(label: "video data queue",
                                                qos: .userInitiated,
                                                attributes: [],
                                                autoreleaseFrequency: .workItem)
    private var videoOutput: AVCaptureVideoDataOutput?

    var currentPosition: AVCaptureDevice.Position = .front

    var flashMode: AVCaptureDevice.FlashMode = .auto

    /// Configures and starts an AV capture session. Requests access for video  capture if needed.
    func begin() {
        Task { [weak self] in
            let authorized = await AVCaptureDevice.requestAccess(for: AVMediaType.video)

            guard authorized else { return }

            self?.configureCaptureSession()
            self?.session.startRunning()
        }
    }

    func stop() {
        self.session.stopRunning()

        self.session.inputs.forEach { input in
            self.session.removeInput(input)
        }

        self.session.outputs.forEach { output in
            self.session.removeOutput(output)
        }
    }

    private func configureCaptureSession() {
        // Define the capture device we want to use
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: self.currentPosition) else {
            return
        }

        // Connect the camera to the capture session input
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if self.session.inputs.isEmpty, self.session.canAddInput(cameraInput) {
                self.session.addInput(cameraInput)
            }
        } catch {
            fatalError(error.localizedDescription)
        }

        // Create the video data output
        self.videoOutput = AVCaptureVideoDataOutput()
        
        guard let videoOutput = self.videoOutput else {
            return
        }

        videoOutput.setSampleBufferDelegate(self.avCaptureDelegate, queue: self.dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        // Add the video output to the capture session
        guard self.session.canAddOutput(videoOutput), !self.session.outputs.contains(where: { output in
            return output is AVCaptureVideoDataOutput
        }) else { return }
        self.session.addOutput(videoOutput)

        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait

        // Get an instance of ACCapturePhotoOutput class
        self.capturePhotoOutput = AVCapturePhotoOutput()
        self.capturePhotoOutput?.isHighResolutionCaptureEnabled = true
        // Set the output on the capture session
        guard let photoOutput = self.capturePhotoOutput,
              self.session.canAddOutput(photoOutput),
              !self.session.outputs.contains(where: { output in
                  return output is AVCapturePhotoOutput
              }) else { return }
        
        self.session.addOutput(self.capturePhotoOutput)
    }

    // MARK: - Photo Capture

    /// Captures a photo of the current state of the capture output.
    func capturePhoto() {
        // Make sure capturePhotoOutput is valid
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        // Get an instance of AVCapturePhotoSettings class
        let photoSettings = AVCapturePhotoSettings()
        // Set photo settings for our need
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = self.flashMode
        // Call capturePhoto method by passing our photo settings and a
        // delegate implementing AVCapturePhotoCaptureDelegate
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self.avCaptureDelegate!)
    }
}
