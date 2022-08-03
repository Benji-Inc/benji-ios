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

 class MomentViewController: ViewController {

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

     lazy var expressionCaptureVC = ExpressionVideoCaptureViewController()
     lazy var momentCatureVC = MomentVideoCaptureViewController()

     var didCompleteMoment: ((Moment) -> Void)? = nil

     @Published var state: State = .initial

     private var expressionData: Data?
     private var expressionURL: URL?

     private var momentData: Data?
     private var momentURL: URL?

     static let maxDuration: TimeInterval = 3.0

     var animation = CABasicAnimation(keyPath: "strokeEnd")

     lazy var shapeLayer: CAShapeLayer = {
         let shapeLayer = CAShapeLayer()
         let color = ThemeColor.D6.color.cgColor
         shapeLayer.fillColor = ThemeColor.clear.color.cgColor
         shapeLayer.strokeColor = color
         shapeLayer.lineCap = .round
         shapeLayer.lineWidth = 4
         shapeLayer.shadowColor = color
         shapeLayer.shadowRadius = 5
         shapeLayer.shadowOffset = .zero
         shapeLayer.shadowOpacity = 1.0
         return shapeLayer
     }()

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

         self.view.addSubview(self.blurView)

         self.addChild(viewController: self.momentCatureVC)
//         self.momentCatureVC.videoPreviewView.shouldPlay = true
//
//         self.addChild(viewController: self.expressionCaptureVC)
//         self.expressionCaptureVC.videoPreviewView.shouldPlay = true
//         self.expressionCaptureVC.label.removeFromSuperview()

         self.view.addSubview(self.doneButton)
         self.doneButton.set(style: .custom(color: .white, textColor: .B0, text: "Done"))

         self.setupHandlers()
     }

     override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()

         self.blurView.expandToSuperviewSize()

         self.momentCatureVC.view.expandToSuperviewSize()

         self.expressionCaptureVC.view.squaredSize = self.view.width * 0.25
         self.expressionCaptureVC.view.pinToSafeAreaTop()
         self.expressionCaptureVC.view.pinToSafeAreaLeft()

         self.doneButton.setSize(with: self.view.width)
         self.doneButton.centerOnX()

         if self.state == .confirm {
             self.doneButton.pinToSafeAreaBottom()
         } else {
             self.doneButton.top = self.view.height
         }
     }

     private func setupHandlers() {

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
                 guard let moment = await self.createMoment() else { return }
                 self.didCompleteMoment?(moment)
             }
         }

//         if !self.expressionCaptureVC.isSessionRunning {
//             self.expressionCaptureVC.beginSession()
//         }

 //        if !self.momentCatureVC.isSessionRunning {
 //            self.momentCatureVC.beginSession()
 //        }
         
//         self.expressionCaptureVC.$videoCaptureState
//             .removeDuplicates()
//             .mainSink { [unowned self] state in
//
//         }.store(in: &self.cancellables)
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
                     self.momentCatureVC.view.alpha = 1.0
                     self.expressionCaptureVC.view.alpha = 1.0
                 }
             })

             UIView.animate(withDuration: 0.1, delay: duration, options: []) {
                 self.momentCatureVC.view.alpha = 1.0
                // self.expressionCaptureVC.cameraViewContainer.layer.borderColor = ThemeColor.B1.color.cgColor
                 self.expressionCaptureVC.view.alpha = 1.0
             } completion: { _ in
                 //self.expressionCaptureVC.beginSession()
                 //self.momentCatureVC.beginSession()
             }
         case .confirm:
//             self.expressionCaptureVC.animate(text: "Tap to retake")
//             self.expressionCaptureVC.animationView.alpha = 0.0
//             self.expressionCaptureVC.animationView.stop()

             self.stopRecordingAnimation()

             guard let expressionURL = self.expressionURL, let momentURL = self.momentURL else { break }

//             self.expressionCaptureVC.setVideoPreview(with: expressionURL)
//             self.momentCatureVC.setVideoPreview(with: momentURL)

             UIView.animate(withDuration: Theme.animationDurationFast) {
//                 self.momentCatureVC.cameraView.alpha = 0.0
//                 self.expressionCaptureVC.cameraView.alpha = 0.0
                 self.view.layoutNow()
             }
         }
     }

     private func createMoment() async -> Moment? {
         guard let expressionURL = self.expressionURL, let momentURL = self.momentURL else { return nil }

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

         self.beginRecordingAnimation()
     }

     override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesEnded(touches, with: event)
         guard self.state == .capture else { return }

         self.stopRecordingAnimation()
     }

     override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesCancelled(touches, with: event)
         guard self.state == .capture else { return }

         self.stopRecordingAnimation()
     }
 }

 extension MomentViewController: UIAdaptivePresentationControllerDelegate {

     func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
         self.stopRecordingAnimation()
         self.expressionCaptureVC.endVideoCapture()
         self.momentCatureVC.endVideoCapture()
         self.state = .capture
         return true
     }
 }

