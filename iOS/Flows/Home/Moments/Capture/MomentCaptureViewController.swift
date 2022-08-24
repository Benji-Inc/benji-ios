//
//  MomentCaptureViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Parse
import Localization
import Speech
import KeyboardManager

class MomentCaptureViewController: PiPRecordingViewController {
    
    override var analyticsIdentifier: String? {
        return "SCREEN_MOMENT"
    }
    
    let label = ThemeLabel(font: .medium, textColor: .white)
    let textView = CaptionTextView()
    let confirmationView = MomentConfirmationView() 
    
    private lazy var panGestureHandler = MomentSwipeGestureHandler(viewController: self)
    
    private lazy var panRecognizer = SwipeGestureRecognizer { [unowned self] (recognizer) in
        self.panGestureHandler.handle(pan: recognizer)
    }
    
    var didCompleteMoment: CompletionOptional = nil 
    
    static let maxDuration: TimeInterval = 6.0
    let cornerRadius: CGFloat = 30
    var willShowKeyboard: Bool = false
    
    var bottomOffset: CGFloat?
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = self.cornerRadius
        }
        
        self.view.set(backgroundColor: .B0)
        
        self.presentationController?.delegate = self
        
        self.view.insertSubview(self.confirmationView, belowSubview: self.backCameraView)
        
        self.backCameraView.layer.cornerRadius = self.cornerRadius
        self.backCameraView.layer.masksToBounds = true
        
        self.view.addSubview(self.label)
        self.label.showShadow(withOffset: 0, opacity: 1.0)
        
        self.view.addSubview(self.textView)
        
        self.view.addGestureRecognizer(self.panRecognizer)
        
        self.setupHandlers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.confirmationView.expandToSuperviewSize()
        
        if let offset = self.bottomOffset {
            self.backCameraView.bottom = offset
            self.frontCameraView.match(.top, to: .top, of: self.backCameraView, offset: .custom(self.frontCameraView.left))
        }
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.label.match(.top, to: .bottom, of: self.backCameraView, offset: .long)
        self.label.centerOnX()
        
        self.textView.setSize(withMaxWidth: Theme.getPaddedWidth(with: self.view.width))
        self.textView.pinToSafeAreaLeft()
        
        if self.willShowKeyboard {
            self.textView.bottom = self.view.height - KeyboardManager.shared.cachedKeyboardEndFrame.height - Theme.ContentOffset.long.value
        } else {
            self.textView.match(.bottom, to: .bottom, of: self.backCameraView, offset: .negative(.custom(self.textView.left)))
        }
    }
    
    private func setupHandlers() {
        
        self.panGestureHandler.didFinish = { [unowned self] in
            logDebug("Did finish")
            
            Task {
                guard let recording = self.recording else { return }
                await self.confirmationView.uploadMoment(from: recording, caption: self.textView.text)
                await Task.sleep(seconds: 1.0)
                self.didCompleteMoment?()
            }
        }
        
        self.textView.$publishedText.mainSink { [unowned self] _ in
            self.view.layoutNow()
        }.store(in: &self.cancellables)
        
        self.frontCameraView.animationDidEnd = { [unowned self] in
            guard self.state == .recording else { return }
            self.stopRecording()
        }
        
        self.view.didSelect { [unowned self] in
            if self.textView.isFirstResponder {
                self.textView.resignFirstResponder()
            } else if self.state == .playback {
                self.state = .idle
            }
        }
        
        KeyboardManager.shared.$currentEvent.mainSink { [unowned self] event in
            switch event {
                
            case .willShow(_):
                self.willShowKeyboard = true
                UIView.animate(withDuration: Theme.animationDurationFast) {
                    self.view.layoutNow()
                    self.textView.backgroundColor = ThemeColor.B0.color.withAlphaComponent(0.8)
                }
            case .willHide(_):
                self.willShowKeyboard = false
                UIView.animate(withDuration: Theme.animationDurationFast) {
                    self.view.layoutNow()
                    self.textView.backgroundColor = ThemeColor.B0.color.withAlphaComponent(0.4)
                }
            default:
                break
            }
            
        }.store(in: &self.cancellables)
    }
    
    override func handle(state: State) {
        super.handle(state: state)
        
        switch state {
        case .idle:
            self.textView.alpha = 0
            self.animate(text: "Press and Hold")
        case .recording:
            self.animate(text: "")
        case .playback:
            self.animate(text: "Swipe Up")
        case .error:
            self.animate(text: "Recording Failed")
        case .uploading:
            break 
        }
    }
    
    override func handleSpeech(result: SFSpeechRecognitionResult?) {
        self.textView.animateSpeech(result: result)
        self.view.layoutNow()
    }
    
    private var animateTask: Task<Void, Never>?
    
    func animate(text: Localized) {
        self.animateTask?.cancel()
        
        self.animateTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            await UIView.awaitAnimation(with: .fast, animations: {
                self.label.alpha = 0
            })
            
            guard !Task.isCancelled else { return }
            
            self.label.setText(text)
            self.view.layoutNow()
            
            await UIView.awaitAnimation(with: .fast, animations: {
                self.label.alpha = 1.0
            })
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard self.state == .idle else { return }
        self.startRecording()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard self.state == .recording else { return }
        
        let touch = touches.first?.gestureRecognizers?.first as? SwipeGestureRecognizer
        
        if touch.isNil {
            self.stopRecording()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard self.state == .recording else { return }
        
        let touch = touches.first?.gestureRecognizers?.first as? SwipeGestureRecognizer
        
        if touch.isNil {
            self.stopRecording()
        }
    }
}

extension MomentCaptureViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        self.stopRecording()
        return true
    }
}
