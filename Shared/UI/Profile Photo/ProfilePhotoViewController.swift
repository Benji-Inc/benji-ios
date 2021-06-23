//
//  ProfilePhotoViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 6/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Vision
import MetalKit

class ProfilePhotoViewController: ViewController {

    // The Vision requests and the handler to perform them.
    private let requestHandler = VNSequenceRequestHandler()
    private var facePoseRequest: VNDetectFaceRectanglesRequest!
    private var segmentationRequest = VNGeneratePersonSegmentationRequest()

    @IBOutlet weak var cameraView: MTKView! {
        didSet {
//            guard metalDevice == nil else { return }
//            setupMetal()
//            setupCoreImage()
//            setupCaptureSession()
        }
    }

    // The Metal pipeline.
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!

    // The Core Image pipeline.
    var ciContext: CIContext!
    var currentCIImage: CIImage? {
        didSet {
            self.cameraView.draw()
        }
    }

}
