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

class ImageCaptureViewController: ViewController,
                                  AVCaptureVideoDataOutputSampleBufferDelegate,
                                  AVCapturePhotoCaptureDelegate {

    let session = AVCaptureSession()
    var capturePhotoOutput: AVCapturePhotoOutput!

    let dataOutputQueue = DispatchQueue(label: "video data queue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .workItem)
    private var videoOutput: AVCaptureVideoDataOutput?

    var didCapturePhoto: ((UIImage) -> Void)?
    var currentPosition: AVCaptureDevice.Position = .front

    enum CameraType {
        case front
        case back
    }

    private(set) var cameraType: CameraType = .front
    var flashMode: AVCaptureDevice.FlashMode = .auto
    
    var boxView = BoxView() 

    func begin() {
        Task {
            let authorized = await AVCaptureDevice.requestAccess(for: AVMediaType.video)

            if authorized {
                self.configureCaptureSession()
                self.session.startRunning()
            }
        }.add(to: self.autocancelTaskPool)
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

    func toggleFlash() {
        if self.flashMode == .on {
            self.flashMode = .off
        } else if self.flashMode == .off {
            self.flashMode = .on
        }
    }

    func flipCamera() {
        if self.currentPosition == .front {
            self.currentPosition = .back
        } else {
            self.currentPosition = .front
        }

        self.stop()
        self.begin()
    }

    func configureCaptureSession() {
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
        self.videoOutput!.setSampleBufferDelegate(self, queue: self.dataOutputQueue)
        self.videoOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        // Add the video output to the capture session
        guard self.session.canAddOutput(self.videoOutput!) else { return }
        self.session.addOutput(self.videoOutput!)

        let videoConnection = self.videoOutput?.connection(with: .video)
        videoConnection?.videoOrientation = .portrait

        // Get an instance of ACCapturePhotoOutput class
        self.capturePhotoOutput = AVCapturePhotoOutput()
        self.capturePhotoOutput?.isHighResolutionCaptureEnabled = true
        // Set the output on the capture session
        self.session.addOutput(self.capturePhotoOutput)
    }

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
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        guard let connection = output.connection(with: .video) else { return }
        connection.automaticallyAdjustsVideoMirroring = true

        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage.init(data: imageData , scale: 1.0) else { return }

        self.didCapturePhoto?(image)
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

    }
}
