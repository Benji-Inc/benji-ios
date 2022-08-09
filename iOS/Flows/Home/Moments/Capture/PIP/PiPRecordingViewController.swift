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
        
    lazy var session = AVCaptureMultiCamSession()
    lazy var recorder = PiPRecorder()
    
    enum State {
        case idle
        case starting
        case started
        case capturing
        case ending
        case error
    }

    @Published var state: State = .idle
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    let frontDataOutputQue = DispatchQueue(label: "front data output queue")
    let backDataOutputQue = DispatchQueue(label: "back data output queue")

    let backCameraView = VideoPreviewView()
    let frontCameraView = FrontPreviewVideoView()
    
    var backInput: AVCaptureDeviceInput?
    let backOutput = AVCaptureVideoDataOutput()
    
    var frontInput: AVCaptureDeviceInput?
    let frontOutput = AVCaptureVideoDataOutput()
    
    var backIsSampling: Bool = false
    var frontIsSampling: Bool = false
    
    var isSessionRunning: Bool {
        return self.session.isRunning
    }
    
    private(set) var recording: PiPRecording?
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.backCameraView)
        self.view.addSubview(self.frontCameraView)
        
        // Set up the back video preview views.
        self.backCameraView.videoPreviewLayer.setSessionWithNoConnection(self.session)
        
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
        
        self.recorder.didCapturePIPRecording = { [unowned self] recording in
            self.recording = recording
            self.endSession()
            self.state = .ending
        }
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.handle(state: state)
        }.store(in: &self.cancellables)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.endSession()
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
    
    func handle(state: State) {
        switch state {
        case .idle:
            self.stopPlayback()
            self.beginSession()
        case .starting:
            break
        case .started:
            break
        case .capturing:
            break
        case .ending:
            self.frontCameraView.stopRecordingAnimation()
            self.beginPlayback()
        case .error:
            break
        }
    }
    
    // MARK: - PRIVATE
    
    // Must be called on the session queue
    private func configureSession() {
        guard self.state == .idle else { return }
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            logDebug("MultiCam not supported on this device")
            self.state = .error
            return
        }
        
        // When using AVCaptureMultiCamSession, it is best to manually add connections from AVCaptureInputs to AVCaptureOutputs
        self.session.beginConfiguration()
        
        defer {
            self.session.commitConfiguration()
            if self.state == .idle {
                self.checkSystemCost()
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
    
    private func beginSession() {
        self.sessionQueue.async { [unowned self] in
            guard !self.isSessionRunning else { return }
            self.session.startRunning()
        }
    }
    
    private func endSession() {
        self.sessionQueue.async { [unowned self] in
            guard self.isSessionRunning else { return }
            self.session.stopRunning()
        }
    }
    
    private func beginPlayback() {
        guard let frontURL = self.recording?.frontRecordingURL,
                let backURL = self.recording?.backRecordingURL else { return }

        logDebug("front: \(frontURL)")
        logDebug("back: \(backURL)")
        self.frontCameraView.beginPlayback(with: frontURL)
        self.backCameraView.beginPlayback(with: backURL)
    }

    private func stopPlayback() {
        self.frontCameraView.stopPlayback()
        self.backCameraView.stopPlayback()
    }
}
