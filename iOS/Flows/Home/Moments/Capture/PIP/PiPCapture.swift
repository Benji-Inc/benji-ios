//
//  PiPCaptureSession.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import Combine
import UIKit

typealias PiPCaptureDelegate = AVCaptureVideoDataOutputSampleBufferDelegate 

class PiPCapture {
    
    enum State: String {
        case success
        case notAuthorized
        case configurationFailed
        case multiCamNotSupported
    }
    
    @Published var state: State = .success

    unowned let delegate: PiPCaptureDelegate

    var isRunning: Bool {
        return self.session.isRunning
    }

    private(set) lazy var session = AVCaptureMultiCamSession()
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    let dataOutputQueue = DispatchQueue(label: "data output queue")

    var backInput: AVCaptureDeviceInput?
    let backOutput = AVCaptureVideoDataOutput()
    
    var frontInput: AVCaptureDeviceInput?
    let frontOutput = AVCaptureVideoDataOutput()
    
    let frontPreviewLayer: AVCaptureVideoPreviewLayer
    let backPreviewLayer: AVCaptureVideoPreviewLayer
        
    init(delegate: PiPCaptureDelegate,
         frontPreviewLayer: AVCaptureVideoPreviewLayer,
         backPreviewLayer: AVCaptureVideoPreviewLayer) {
        
        self.delegate = delegate
        self.frontPreviewLayer = frontPreviewLayer
        self.backPreviewLayer = backPreviewLayer
        /*
        Configure the capture session.
        In general it is not safe to mutate an AVCaptureSession or any of its
        inputs, outputs, or connections from multiple threads at the same time.
        
        Don't do this on the main queue, because AVCaptureMultiCamSession.startRunning()
        is a blocking call, which can take a long time. Dispatch session setup
        to the sessionQueue so as not to block the main queue, which keeps the UI responsive.
        */
        self.sessionQueue.async {
            self.configureSession()
            self.begin()
        }
    }
    
    // Must be called on the session queue
    private func configureSession() {
        guard self.state == .success else { return }
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            logDebug("MultiCam not supported on this device")
            self.state = .multiCamNotSupported
            return
        }
        
        // When using AVCaptureMultiCamSession, it is best to manually add connections from AVCaptureInputs to AVCaptureOutputs
        self.session.beginConfiguration()
        
        defer {
            self.session.commitConfiguration()
            if self.state == .success {
                self.checkSystemCost()
            }
        }
    
        guard self.configureBackCamera() else {
            self.state = .configurationFailed
            return
        }

        guard self.configureFrontCamera() else {
            self.state = .configurationFailed
            return
        }
    }

    /// Configures and starts an AV capture session. Requests access for video  capture if needed.
    func begin() {
        self.sessionQueue.async {
            logDebug(self.state.rawValue)
            switch self.state {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.session.startRunning()
                
            case .notAuthorized:
                break
            case .configurationFailed:
                break
            case .multiCamNotSupported:
                break
            }
        }
    }

    /// Stops the AV capture session and cleans up inputs and outputs.
    func stop() {
        
        self.sessionQueue.async {
            if self.state == .success {
                self.session.stopRunning()

                self.session.inputs.forEach { input in
                    self.session.removeInput(input)
                }

                self.session.outputs.forEach { output in
                    self.session.removeOutput(output)
                }
            }
        }
    }

//    private func configureCaptureSession() {
//        // Define the capture device we want to use
//        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
//                                                   for: .video,
//                                                   position: .front) else {
//            return
//        }
//
//        // Connect the camera to the capture session input
//        do {
//            let cameraInput = try AVCaptureDeviceInput(device: camera)
//            if self.session.inputs.isEmpty, self.session.canAddInput(cameraInput) {
//                self.session.addInput(cameraInput)
//            }
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        // Create the video data output
//        self.videoOutput = AVCaptureVideoDataOutput()
//
//        guard let videoOutput = self.videoOutput else { return }
//
//        videoOutput.setSampleBufferDelegate(self.avCaptureDelegate, queue: self.dataOutputQueue)
//        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
//
//        // Add the video output to the capture session
//        guard self.session.canAddOutput(videoOutput), self.session.outputs.first(where: { output in
//            return output is AVCaptureVideoDataOutput
//        }).isNil else { return }
//
//        self.session.addOutput(videoOutput)
//
//        let videoConnection = videoOutput.connection(with: .video)
//        videoConnection?.videoOrientation = .portrait
//    }
}
