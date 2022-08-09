//
//  PiPRecordingViewController+Cameras.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation

extension PiPRecordingViewController {
    
    func configureBackCamera() -> Bool {
        
        // Find the back camera
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find the back camera")
            return false
        }
        
        // Add the back camera input to the session
        do {
            self.backInput = try AVCaptureDeviceInput(device: backCamera)
            
            guard let backCameraDeviceInput = self.backInput,
                  self.session.canAddInput(backCameraDeviceInput) else {
                    print("Could not add back camera device input")
                    return false
            }
            self.session.addInputWithNoConnections(backCameraDeviceInput)
        } catch {
            print("Could not create back camera device input: \(error)")
            return false
        }
        
        // Find the back camera device input's video port
        guard let backCameraDeviceInput = self.backInput,
            let backCameraVideoPort = backCameraDeviceInput.ports(for: .video,
                                                              sourceDeviceType: backCamera.deviceType,
                                                              sourceDevicePosition: backCamera.position).first else {
                                                                print("Could not find the back camera device input's video port")
                                                                return false
        }
        
        // Add the back camera video data output
        guard self.session.canAddOutput(self.backOutput) else {
            print("Could not add the back camera video data output")
            return false
        }
        self.session.addOutputWithNoConnections(self.backOutput)
        // Check if CVPixelFormat Lossy or Lossless Compression is supported
        
        if self.backOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossy_32BGRA) {
            // Set the Lossy format
            print("Selecting lossy pixel format")
            self.backOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossy_32BGRA)]
        } else if self.backOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossless_32BGRA) {
            // Set the Lossless format
            print("Selecting a lossless pixel format")
            self.backOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossless_32BGRA)]
        } else {
            // Set to the fallback format
            print("Selecting a 32BGRA pixel format")
            self.backOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        }
        
        self.backOutput.setSampleBufferDelegate(self, queue: self.backDataOutputQue)
                
        // Connect the back camera device input to the back camera video data output
        let backCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [backCameraVideoPort],
                                                                      output: self.backOutput)
        
        guard self.session.canAddConnection(backCameraVideoDataOutputConnection) else {
            print("Could not add a connection to the back camera video data output")
            return false
        }
        self.session.addConnection(backCameraVideoDataOutputConnection)
        backCameraVideoDataOutputConnection.videoOrientation = .portrait

        Task.onMainActor {
            // Connect the back camera device input to the back camera video preview layer
            let backCameraVideoPreviewLayerConnection = AVCaptureConnection(inputPort: backCameraVideoPort,
                                                                            videoPreviewLayer: self.backCameraView.videoPreviewLayer)
            guard self.session.canAddConnection(backCameraVideoPreviewLayerConnection) else {
                print("Could not add a connection to the back camera video preview layer")
                return 
            }
            self.session.addConnection(backCameraVideoPreviewLayerConnection)
        }
        
        return true
    }
    
    func configureFrontCamera() -> Bool {
        
        // Find the front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Could not find the front camera")
            return false
        }
        
        // Add the front camera input to the session
        do {
            self.frontInput = try AVCaptureDeviceInput(device: frontCamera)
            
            guard let frontCameraDeviceInput = self.frontInput,
                  self.session.canAddInput(frontCameraDeviceInput) else {
                    print("Could not add front camera device input")
                    return false
            }
            self.session.addInputWithNoConnections(frontCameraDeviceInput)
        } catch {
            print("Could not create front camera device input: \(error)")
            return false
        }
        
        // Find the front camera device input's video port
        guard let frontCameraDeviceInput = self.frontInput,
            let frontCameraVideoPort = frontCameraDeviceInput.ports(for: .video,
                                                                    sourceDeviceType: frontCamera.deviceType,
                                                                    sourceDevicePosition: frontCamera.position).first else {
                                                                        print("Could not find the front camera device input's video port")
                                                                        return false
        }
        
        // Add the front camera video data output
        guard self.session.canAddOutput(self.frontOutput) else {
            print("Could not add the front camera video data output")
            return false
        }
        self.session.addOutputWithNoConnections(self.frontOutput)
        // Check if CVPixelFormat Lossy or Lossless Compression is supported
        
        if self.frontOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossy_32BGRA) {
            // Set the Lossy format
            self.frontOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossy_32BGRA)]
        } else if self.frontOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossless_32BGRA) {
            // Set the Lossless format
            self.frontOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossless_32BGRA)]
        } else {
            // Set to the fallback format
            self.frontOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        }

        self.frontOutput.setSampleBufferDelegate(self, queue: self.frontDataOutputQue)
        
        // Connect the front camera device input to the front camera video data output
        let frontCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [frontCameraVideoPort],
                                                                       output: self.frontOutput)
        guard self.session.canAddConnection(frontCameraVideoDataOutputConnection) else {
            print("Could not add a connection to the front camera video data output")
            return false
        }
        
        frontCameraVideoDataOutputConnection.videoOrientation = .portrait
        frontCameraVideoDataOutputConnection.automaticallyAdjustsVideoMirroring = false
        frontCameraVideoDataOutputConnection.isVideoMirrored = true
        
        self.session.addConnection(frontCameraVideoDataOutputConnection)
        
        return true
    }
}
