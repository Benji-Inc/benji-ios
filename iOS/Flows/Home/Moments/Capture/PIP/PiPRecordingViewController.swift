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

class PiPRecordingViewController: ViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    lazy var pipCapture = PiPCapture(delegate: self,
                                     frontPreviewLayer: self.frontCameraView.videoPreviewLayer,
                                     backPreviewLayer: self.backCameraView.videoPreviewLayer)
    
    lazy var recorder = PiPRecorder(frontVideoSettings: [:], backVideoSettings: [:])
    
    let backCameraView = VideoPreviewView()
    let frontCameraView = FrontPreviewVideoView()
    
    /// A request to separate a person from the background in an image.
    private var segmentationRequest = VNGeneratePersonSegmentationRequest()
    private var sequenceHandler = VNSequenceRequestHandler()
    
    var isSessionRunning: Bool {
        return self.pipCapture.isRunning
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.backCameraView)
        self.view.addSubview(self.frontCameraView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.backCameraView.videoPreviewLayer.session.isNil {
            // Set up the back and front video preview views.
            self.backCameraView.videoPreviewLayer.setSessionWithNoConnection(self.pipCapture.session)
            self.frontCameraView.videoPreviewLayer.setSessionWithNoConnection(self.pipCapture.session)
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
        self.pipCapture.begin()
    }
    
    func stopSession() {
        self.pipCapture.stop()
        self.frontCameraView.currentCIImage = nil
    }
    
    func startVideoCapture() {
       // self.recorder.startRecording(frontSampleBuffer: <#T##CMSampleBuffer#>, backSampleBuffer: <#T##CMSampleBuffer#>)
    }
    
    func stopVideoCapture() {
        self.recorder.stopRecording()
    }
    
    func beginPlayback() {
        guard let frontURL = self.recorder.recording?.frontRecordingURL,
                let backURL = self.recorder.recording?.backRecordingURL else { return }
        
        self.frontCameraView.beginPlayback(with: frontURL)
        self.backCameraView.beginPlayback(with: backURL)
    }
    
    func stopPlayback() {
        self.frontCameraView.stopPlayback()
        self.backCameraView.stopPlayback()
    }
}
