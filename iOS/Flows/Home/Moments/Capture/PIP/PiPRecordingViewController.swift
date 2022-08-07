//
//  PiPRecordingViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import Vision

class PiPRecordingViewController: ViewController, AVCaptureVideoDataOutputSampleBufferDelegate  {
    
    /// A request to separate a person from the background in an image.
    let segmentationRequest = VNGeneratePersonSegmentationRequest()
    let sequenceHandler = VNSequenceRequestHandler()
    
    @Published var faceDetected = false
    
    lazy var session = AVCaptureMultiCamSession()
    lazy var recorder = PiPRecorder()
    
    enum State {
        case setup
        case idle
        case displaying
        case recording
        case playback
        case confirm
        case error
    }

    @Published var state: State = .idle
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    let frontDataOutputQueue = DispatchQueue(label: "front data output queue")
    let backDataOutputQueue = DispatchQueue(label: "front data output queue")
    
    let backCameraView = VideoPreviewView()
    let frontCameraView = FrontPreviewVideoView()
    
    var backInput: AVCaptureDeviceInput?
    let backOutput = AVCaptureVideoDataOutput()
    
    var frontInput: AVCaptureDeviceInput?
    let frontOutput = AVCaptureVideoDataOutput()
    
    var isSessionRunning: Bool {
        return self.session.isRunning
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.backCameraView)
        self.view.addSubview(self.frontCameraView)
        
        // Set up the back and front video preview views.
        self.backCameraView.videoPreviewLayer.setSessionWithNoConnection(self.session)
        self.frontCameraView.videoPreviewLayer.setSessionWithNoConnection(self.session)
        
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
        }
    }
    
    // Must be called on the session queue
    private func configureSession() {
        guard self.state == .setup else { return }
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            logDebug("MultiCam not supported on this device")
            self.state = .error
            return
        }
        
        // When using AVCaptureMultiCamSession, it is best to manually add connections from AVCaptureInputs to AVCaptureOutputs
        self.session.beginConfiguration()
        
        defer {
            self.session.commitConfiguration()
            if self.state == .setup {
                self.checkSystemCost()
                self.state = .idle
            }
        }
    
        guard self.configureBackCamera() else {
            self.state = .error
            return
        }
        
        guard self.configureFrontCamera() else {
            self.state = .error
            return
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.stopSession()
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.backCameraView.expandToSuperviewSize()
        
        self.frontCameraView.squaredSize = self.view.width * 0.25
        self.frontCameraView.pinToSafeAreaTop()
        self.frontCameraView.pinToSafeAreaLeft()
    }
    
    // MARK: - PUBLIC
    
    func beginSession() {
        guard self.state == .idle else { return }
        self.session.startRunning()
    }
    
    func stopSession() {
        self.sessionQueue.async {
            if self.isSessionRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func startVideoCapture() {
        self.state = .recording
    }
    
    func stopVideoCapture() {
        self.state = .playback
    }
    
    func beginPlayback() {
        guard let frontURL = self.recorder.recording?.frontRecordingURL,
                let backURL = self.recorder.recording?.backRecordingURL else { return }
        
        logDebug("front: \(frontURL)")
        logDebug("back: \(backURL)")
        self.frontCameraView.beginPlayback(with: frontURL)
        self.backCameraView.beginPlayback(with: backURL)
    }
    
    func stopPlayback() {
        self.frontCameraView.stopPlayback()
        self.backCameraView.stopPlayback()
    }
}
