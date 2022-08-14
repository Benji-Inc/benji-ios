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
import Speech

class PiPRecordingViewController: ViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
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
        case playback
        case error
    }

    @Published var state: State = .idle
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    let frontDataOutputQue = DispatchQueue(label: "front data output queue")
    let backDataOutputQue = DispatchQueue(label: "back data output queue")
    let micDataOutputQue = DispatchQueue(label: "mic data output queue")

    let backCameraView = VideoPreviewView()
    let frontCameraView = FrontPreviewVideoView()
    
    var backInput: AVCaptureDeviceInput?
    let backOutput = AVCaptureVideoDataOutput()
    
    var frontInput: AVCaptureDeviceInput?
    let frontOutput = AVCaptureVideoDataOutput()
    
    var micInput: AVCaptureDeviceInput?
    let micDataOutput = AVCaptureAudioDataOutput()
    
    var backIsSampling: Bool = false
    var frontIsSampling: Bool = false
    var micIsSampling: Bool = false 
    
    var isSessionRunning: Bool {
        return self.session.isRunning
    }
    
    var isSessiongBeingConfigured: Bool = false
    
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
            self.state = .playback
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
            break
        case .playback:
            self.endSession()
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
        self.isSessiongBeingConfigured = true
        
        defer {
            self.session.commitConfiguration()
            if self.state == .idle {
                self.checkSystemCost()
            }
            self.isSessiongBeingConfigured = false
        }
    
        guard self.configureBackCamera() else {
            self.state = .error
            return
        }
        
        guard self.configureFrontCamera() else {
            self.state = .error
            return
        }
        
        guard self.configureMicrophone() else {
            self.state = .error
            return
        }
    }
    
    private func beginSession() {
        self.sessionQueue.async { [unowned self] in
            guard !self.isSessionRunning, !self.isSessiongBeingConfigured else { return }
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

        self.frontCameraView.beginPlayback(with: frontURL)
        self.backCameraView.beginPlayback(with: backURL)
        
        Task.onMainActorAsync {
            let status = await self.requestTranscribePermissions()
            guard status == .authorized else { return }
            self.transcribeAudio(url: frontURL)
        }
    }

    private func stopPlayback() {
        self.frontCameraView.stopPlayback()
        self.backCameraView.stopPlayback()
    }
    
    @MainActor
    func requestTranscribePermissions() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation({ continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                continuation.resume(returning: authStatus)
            }
        })
    }
    
    func transcribeAudio(url: URL) {
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                logDebug("There was an error: \(error!)")
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                logDebug(result.bestTranscription.formattedString)
            }
        }
    }
}
