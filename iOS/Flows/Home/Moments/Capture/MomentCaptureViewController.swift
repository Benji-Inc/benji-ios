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

 class MomentCaptureViewController: PiPRecordingViewController {

     enum State {
         case initial
         case capture
         case confirm
     }

     override var analyticsIdentifier: String? {
         return "SCREEN_MOMENT"
     }

     private let blurView = DarkBlurView()
     private let bottomGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                              startPoint: .bottomCenter,
                                                              endPoint: .topCenter)
     private let label = ThemeLabel(font: .medium, textColor: .white)
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
         
         self.view.addSubview(self.bottomGradientView)
         self.view.addSubview(self.label)
         self.label.showShadow(withOffset: 0)

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
         
         self.bottomGradientView.expandToSuperviewWidth()
         self.bottomGradientView.height = self.view.height - (self.label.top - Theme.ContentOffset.long.value)
         self.bottomGradientView.pin(.bottom)
     }

     private func setupHandlers() {
         
         self.frontCameraView.animationDidStart = { [unowned self] in
             self.animate(text: "")
             self.startVideoCapture()
         }
         
         self.frontCameraView.animationDidEnd = { [unowned self] in
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
         case .capture:
             self.stopPlayback()
             self.animate(text: "Press and Hold")

             let duration: TimeInterval = 0.25

             UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                 UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
                     self.backCameraView.videoPreviewLayer.opacity = 1
                     self.frontCameraView.cameraView.alpha = 1
                     self.view.layoutNow()
                 }

                 UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                     self.backCameraView.alpha = 1.0
                     self.frontCameraView.alpha = 1.0
                 }
             })

             UIView.animate(withDuration: 0.1, delay: duration, options: []) {
                 self.backCameraView.alpha = 1.0
                 self.frontCameraView.layer.borderColor = ThemeColor.whiteWithAlpha.color.cgColor
                 self.frontCameraView.alpha = 1.0
             } completion: { _ in
                 self.beginSession()
             }
         case .confirm:
             self.animate(text: "Tap to retake")
             self.frontCameraView.stopRecordingAnimation()
             self.beginPlayback()

             UIView.animate(withDuration: Theme.animationDurationFast) {
                 self.backCameraView.videoPreviewLayer.opacity = 0.0
                 self.frontCameraView.cameraView.alpha = 0.0
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

         self.frontCameraView.beginRecordingAnimation()
     }

     override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesEnded(touches, with: event)
         guard self.state == .capture else { return }

         self.frontCameraView.stopRecordingAnimation()
     }

     override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesCancelled(touches, with: event)
         guard self.state == .capture else { return }

         self.frontCameraView.stopRecordingAnimation()
     }
 }

 extension MomentCaptureViewController: UIAdaptivePresentationControllerDelegate {

     func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
         self.frontCameraView.stopRecordingAnimation()
         self.stopVideoCapture()
         self.state = .capture
         return true
     }
 }

