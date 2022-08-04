//
//  MomentViewController+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import QuartzCore

 extension MomentCaptureViewController {

     func beginRecordingAnimation() {

     }

     func stopRecordingAnimation() {
         
     }
 }

 extension MomentCaptureViewController: CAAnimationDelegate {

     func animationDidStart(_ anim: CAAnimation) {

     }

     func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
         if self.state == .capture {

         }
     }
 }
