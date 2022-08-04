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

         self.view.addSubview(self.doneButton)
         self.doneButton.set(style: .custom(color: .white, textColor: .B0, text: "Done"))
         
         self.setupHandlers()
     }

     override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()

         self.blurView.expandToSuperviewSize()
         
         self.doneButton.setSize(with: self.view.width)
         self.doneButton.centerOnX()

         if self.state == .confirm {
             self.doneButton.pinToSafeAreaBottom()
         } else {
             self.doneButton.top = self.view.height
         }
     }

     private func setupHandlers() {
         
         self.frontCameraVideoPreviewView.animationDidStart = { [unowned self] in
             
         }
         
         self.frontCameraVideoPreviewView.animationDidEnd = { [unowned self] in
             
         }
         
         self.recorder.didCapturePIPRecording = { [unowned self] in
             self.stopSession()
             self.state = .confirm
         }

//         self.momentCatureVC.didCaptureVideo = { [unowned self] videoURL in
//             self.momentURL = videoURL
//
//             Task.onMainActor {
//                 self.momentCatureVC.stopSession()
//                 self.state = .confirm
//             }
//         }
//
//         self.expressionCaptureVC.didCaptureVideo = { [unowned self] videoURL in
//             self.expressionURL = videoURL
//
//             Task.onMainActor {
//                 self.expressionCaptureVC.stopSession()
//                 self.state = .confirm
//             }
//         }
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
             break
             //self.expressionCaptureVC.animate(text: "Scanning...")
//             self.expressionCaptureVC.animationView.alpha = 1.0
//             self.expressionCaptureVC.animationView.play()
         case .capture:
             //self.momentCatureVC.setVideoPreview(with: nil)

             //self.expressionCaptureVC.animationView.stop()
             //self.expressionCaptureVC.animate(text: "Press and Hold")
             //self.expressionCaptureVC.setVideoPreview(with: nil)

             let duration: TimeInterval = 0.25

             UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                 UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
//                     self.momentCatureVC.cameraView.alpha = 1
//
//                     self.expressionCaptureVC.cameraView.alpha = 1
//                     self.expressionCaptureVC.animationView.alpha = 0.0
                     self.view.layoutNow()
                 }

                 UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
//                     self.momentCatureVC.view.alpha = 1.0
//                     self.expressionCaptureVC.view.alpha = 1.0
                 }
             })

             UIView.animate(withDuration: 0.1, delay: duration, options: []) {
                 //self.momentCatureVC.view.alpha = 1.0
                // self.expressionCaptureVC.cameraViewContainer.layer.borderColor = ThemeColor.B1.color.cgColor
                // self.expressionCaptureVC.view.alpha = 1.0
             } completion: { _ in
                 self.beginSession()
                 //self.expressionCaptureVC.beginSession()
                 //self.momentCatureVC.beginSession()
             }
         case .confirm:
//             self.expressionCaptureVC.animate(text: "Tap to retake")
//             self.expressionCaptureVC.animationView.alpha = 0.0
//             self.expressionCaptureVC.animationView.stop()

             self.frontCameraVideoPreviewView.stopRecordingAnimation()

             guard let expressionURL = self.recorder.recording?.frontRecordingURL,
                   let momentURL = self.recorder.recording?.backRecordingURL else { break }

//             self.expressionCaptureVC.setVideoPreview(with: expressionURL)
//             self.momentCatureVC.setVideoPreview(with: momentURL)

             UIView.animate(withDuration: Theme.animationDurationFast) {
//                 self.momentCatureVC.cameraView.alpha = 0.0
//                 self.expressionCaptureVC.cameraView.alpha = 0.0
                 self.view.layoutNow()
             }
         }
     }

     private func createMoment(from recording: PiPRecording) async -> Moment? {
         guard let expressionURL = recording.frontRecordingURL, let momentURL = recording.backRecordingURL else { return nil }

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

