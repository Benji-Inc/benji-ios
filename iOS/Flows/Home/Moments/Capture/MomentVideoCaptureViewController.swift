//
//  MomentVideoCaptureViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation

 class MomentVideoCaptureViewController: ViewController {

//     lazy var previewLayer: AVCaptureVideoPreviewLayer = {
//         return AVCaptureVideoPreviewLayer(session: self.captureSession.session)
//     }()

     // MARK: - Life Cycle

     override func initializeViews() {
         super.initializeViews()

//         self.cameraViewContainer.layer.addSublayer(self.previewLayer)
//         self.previewLayer.videoGravity = .resizeAspectFill
//
//         self.captureSession.currentPosition = .back
//         self.captureSession.flashMode = .off
     }

     override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()

//         self.cameraViewContainer.expandToSuperviewSize()
//         self.previewLayer.frame = self.cameraViewContainer.bounds
     }

     func beginVideoCapture() {
//         if self.isSessionRunning {
//             self.startVideoCapture()
//         } else {
//             self.view.isVisible = true
//             self.beginSession()
//         }
     }

     func endVideoCapture() {
//         switch self.videoCaptureState {
//         case .starting, .started, .capturing:
//             self.finishVideoCapture()
//         case .idle, .ending:
//             break
//         }
     }
 }
