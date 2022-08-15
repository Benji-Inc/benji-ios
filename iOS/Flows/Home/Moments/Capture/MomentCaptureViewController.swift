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

     override var analyticsIdentifier: String? {
         return "SCREEN_MOMENT"
     }

     private let label = ThemeLabel(font: .medium, textColor: .white)
     private let doneButton = ThemeButton()

     var didCompleteMoment: ((Moment) -> Void)? = nil

     static let maxDuration: TimeInterval = 6.0
     let cornerRadius: CGFloat = 30

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

         self.backCameraView.layer.cornerRadius = self.cornerRadius

         self.view.addSubview(self.label)
         self.label.showShadow(withOffset: 0, opacity: 1.0)

         self.view.addSubview(self.doneButton)
         self.doneButton.set(style: .custom(color: .white, textColor: .B0, text: "Done"))
         
         self.setupHandlers()
     }

     override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
                  
         self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
         self.label.centerOnX()
         
         self.doneButton.setSize(with: self.view.width)
         self.doneButton.centerOnX()

         if self.state == .playback, !self.isBeingClosed {
             self.doneButton.pinToSafeAreaBottom()
             self.label.match(.bottom, to: .top, of: self.doneButton, offset: .negative(.long))
         } else {
             self.doneButton.top = self.view.height
             self.label.pinToSafeAreaBottom()
         }
     }

     private func setupHandlers() {
                  
         self.frontCameraView.animationDidStart = { [unowned self] in
             self.animate(text: "")
             self.state = .initialize
         }
         
         self.frontCameraView.animationDidEnd = { [unowned self] in
             self.state = .ending
         }

         self.view.didSelect { [unowned self] in
             guard self.state == .playback else { return }
             self.state = .idle
         }

         self.doneButton.didSelect { [unowned self] in
             Task {
                 guard let recording = self.recording,
                       let moment = await self.createMoment(from: recording) else { return }
                 self.didCompleteMoment?(moment)
             }
         }
     }

     override func handle(state: State) {
         super.handle(state: state)
         
         switch state {
         case .idle:
             self.animate(text: "Press and Hold")
         case .playback:
             self.animate(text: "")
         default:
             break
         }
     }

     private func createMoment(from recording: PiPRecording) async -> Moment? {
         await self.doneButton.handleEvent(status: .loading)
         
         do {
             return  try await MomentsStore.shared.createMoment(from: recording)
         } catch {
             await self.doneButton.handleEvent(status: .error("Error"))
             return nil
         }
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

         self.frontCameraView.beginRecordingAnimation()
     }

     override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesEnded(touches, with: event)
         guard self.frontCameraView.isAnimating else { return }

         self.frontCameraView.stopRecordingAnimation()
     }

     override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesCancelled(touches, with: event)
         guard self.frontCameraView.isAnimating else { return }

         self.frontCameraView.stopRecordingAnimation()
     }
 }

 extension MomentCaptureViewController: UIAdaptivePresentationControllerDelegate {

     func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
         self.frontCameraView.stopRecordingAnimation()
         return true
     }
 }
