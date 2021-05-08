//
//  LivePhotoViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import Combine

class ImageCaptureViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {

    var cancellables = Set<AnyCancellable>()

    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
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

    var isAuthorized: Bool {
        return AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == AVAuthorizationStatus.authorized
    }

    private(set) var cameraType: CameraType = .front
    var flashMode: AVCaptureDevice.FlashMode = .auto

    func requestAthorization() -> Future<Bool, Never> {
        return Future { promise in
            if self.isAuthorized {
                promise(.success(true))
            } else {
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
                    promise(.success(granted))
                })
            }
        }
    }

    func begin() {
        self.requestAthorization()
            .mainSink { authorized in
                if authorized {
                    self.configureCaptureSession()
                    self.session.startRunning()
                }
            }.store(in: &self.cancellables)
    }

    func stop() {
        self.session.stopRunning()

        self.session.inputs.forEach { input in
            self.session.removeInput(input)
        }

        self.session.outputs.forEach { output in
            self.session.removeOutput(output)
        }

        self.previewLayer.removeFromSuperlayer()
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

        // Configure the preview layer
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer.frame = self.view.bounds

        self.view.layer.insertSublayer(self.previewLayer, at: 0)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let layer = self.previewLayer {
            layer.frame = self.view.bounds
        }
    }
}
