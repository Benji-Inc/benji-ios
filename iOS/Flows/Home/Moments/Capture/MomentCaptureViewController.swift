//
//  MomentViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Parse
import Localization

 class MomentCaptureViewController: PiPRecordingViewController {

     enum State {
         case initial
         case capture
         case confirm
     }

     override var analyticsIdentifier: String? {
         return "SCREEN_MOMENT"
     }

     let blurView = DarkBlurView()
     let label = ThemeLabel(font: .medium, textColor: .white)

     private let doneButton = ThemeButton()

     var didCompleteMoment: ((Moment) -> Void)? = nil

     @Published var state: State = .initial

     static let maxDuration: TimeInterval = 3.0

     override func initializeViews() {
         super.initializeViews()

         self.modalPresentationStyle = .popover
         if let pop = self.popoverPresentationController {
             let sheet = pop.adaptiveSheetPresentationController
             sheet.detents = [.large()]
             sheet.prefersGrabberVisible = true
             sheet.prefersScrollingExpandsWhenScrolledToEdge = true
         }

         self.presentationController?.delegate = self

         self.view.insertSubview(self.blurView, at: 0)
         
         self.view.addSubview(self.label)

         self.view.addSubview(self.doneButton)
         self.doneButton.set(style: .custom(color: .white, textColor: .B0, text: "Done"))
         
         self.setupHandlers()
     }

     override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()

         self.blurView.expandToSuperviewSize()
         
         self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
         self.label.centerOnX()
         
         self.doneButton.setSize(with: self.view.width)
         self.doneButton.centerOnX()

         if self.state == .confirm {
             self.doneButton.pinToSafeAreaBottom()
             self.label.top = self.view.height
         } else {
             self.doneButton.top = self.view.height
             self.label.pinToSafeAreaBottom()
         }
     }

     private func setupHandlers() {
         
         self.frontCameraVideoPreviewView.animationDidStart = { [unowned self] in
             self.animate(text: "")
             self.startVideoCapture()
         }
         
         self.frontCameraVideoPreviewView.animationDidEnd = { [unowned self] in
             if self.state == .capture {
                 self.stopVideoCapture()
             }
         }
         
         self.recorder.didCapturePIPRecording = { [unowned self] in
             self.stopSession()
             self.state = .confirm
         }

//
//         self.expressionCaptureVC.$hasRenderedFaceImage
//             .removeDuplicates()
//             .mainSink { [unowned self] hasRendered in
//                 if hasRendered {
//                     self.state = .capture
//                 } else {
//                     self.state = .initial
//                 }
//             }.store(in: &self.cancellables)

         self.$state
             .removeDuplicates()
             .mainSink { [unowned self] state in
                 self.update(for: state)
             }.store(in: &self.cancellables)

         self.view.didSelect { [unowned self] in
             guard self.state == .confirm else { return }
             self.state = .capture
         }

         self.doneButton.didSelect { [unowned self] in
             Task {
                 guard let recording = self.recorder.recording,
                       let moment = await self.createMoment(from: recording) else { return }
                 self.didCompleteMoment?(moment)
             }
         }
         
         if !self.isSessionRunning {
             self.beginSession()
         }
     }

     private func update(for state: State) {
         switch state {
         case .initial:
             self.animate(text: "Scanning...")
             self.frontCameraVideoPreviewView.animationView.alpha = 1.0
             self.frontCameraVideoPreviewView.animationView.play()
         case .capture:
             self.stopPlayback()

             self.frontCameraVideoPreviewView.animationView.stop()
             self.animate(text: "Press and Hold")

             let duration: TimeInterval = 0.25

             UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                 UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
                     self.backCameraVideoPreviewView.videoPreviewLayer.opacity = 1

                     self.frontCameraVideoPreviewView.videoPreviewLayer.opacity = 1
                     self.frontCameraVideoPreviewView.animationView.alpha = 0.0
                     
                     self.view.layoutNow()
                 }

                 UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                     self.backCameraVideoPreviewView.alpha = 1.0
                     self.frontCameraVideoPreviewView.alpha = 1.0
                 }
             })

             UIView.animate(withDuration: 0.1, delay: duration, options: []) {
                 self.backCameraVideoPreviewView.alpha = 1.0
                 self.frontCameraVideoPreviewView.layer.borderColor = ThemeColor.B1.color.cgColor
                 self.frontCameraVideoPreviewView.alpha = 1.0
             } completion: { _ in
                 self.beginSession()
             }
         case .confirm:
             self.animate(text: "Tap to retake")
             self.frontCameraVideoPreviewView.animationView.alpha = 0.0
             self.frontCameraVideoPreviewView.animationView.stop()

             self.frontCameraVideoPreviewView.stopRecordingAnimation()
             self.beginPlayback()

             UIView.animate(withDuration: Theme.animationDurationFast) {
                 self.backCameraVideoPreviewView.videoPreviewLayer.opacity = 0.0
                 self.frontCameraVideoPreviewView.videoPreviewLayer.opacity = 0.0
                 self.view.layoutNow()
             }
         }
     }

     private func createMoment(from recording: PiPRecording) async -> Moment? {
         guard let expressionURL = recording.frontRecordingURL,
                let momentURL = recording.backRecordingURL else { return nil }

         let expressionData = try! Data(contentsOf: expressionURL)
         let momentData = try! Data(contentsOf: momentURL)

         let expression = Expression()

         expression.author = User.current()
         expression.file = PFFileObject(name: "expression.mov", data: expressionData)
         expression.emojiString = nil

         guard let savedExpression = try? await expression.saveToServer() else { return nil }

         #warning("Add conversation id to moment creation")

         let moment = Moment()
         moment.expression = savedExpression
         moment.conversationId = "Some conversation ID"
         moment.author = User.current()
         moment.file = PFFileObject(name: "moment.mov", data: momentData)

         guard let savedMoment = try? await moment.saveToServer() else { return nil }

         return savedMoment
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
         guard self.state == .capture else { return }

         self.frontCameraVideoPreviewView.beginRecordingAnimation()
     }

     override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesEnded(touches, with: event)
         guard self.state == .capture else { return }

         self.frontCameraVideoPreviewView.stopRecordingAnimation()
     }

     override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesCancelled(touches, with: event)
         guard self.state == .capture else { return }

         self.frontCameraVideoPreviewView.stopRecordingAnimation()
     }
 }

 extension MomentCaptureViewController: UIAdaptivePresentationControllerDelegate {

     func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
         self.frontCameraVideoPreviewView.stopRecordingAnimation()
         self.stopVideoCapture()
         self.state = .capture
         return true
     }
 }

