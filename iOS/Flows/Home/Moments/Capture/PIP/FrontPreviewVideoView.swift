//
//  FrontPreviewVideoView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import MetalKit

class FrontPreviewVideoView: VideoPreviewView {
    
    let animationView = AnimationView.with(animation: .faceScan)
    
    var animationDidStart: CompletionOptional = nil
    var animationDidEnd: CompletionOptional = nil
    
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
    
    /// Shows a live preview of what the camera is seeing..
    lazy var cameraView: MetalView = {
        let metalView = MetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.delegate = self
        metalView.alpha = 0
        return metalView
    }()
    
    var currentCIImage: CIImage? {
        didSet {
            self.cameraView.draw()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.cameraView)
        
        self.addSubview(self.animationView)
        self.animationView.loopMode = .loop
        self.animationView.alpha = 0
        
        self.layer.borderColor = ThemeColor.whiteWithAlpha.color.cgColor
        self.layer.borderWidth = 4
        
        self.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.cameraView.width = self.width
        self.cameraView.height = self.height * 1.25
        self.cameraView.pin(.top)
        self.cameraView.centerOnX()
        
        self.animationView.squaredSize = self.height * 0.5
        self.animationView.centerOnXAndY()
                
        self.layer.cornerRadius = self.height * 0.25
    }
    
    func beginRecordingAnimation() {
    
        self.shapeLayer.removeFromSuperlayer()
        self.layer.addSublayer(self.shapeLayer)
        
        self.animation.delegate = self
        self.animation.fromValue = 0
        self.animation.duration = ExpressionViewController.maxDuration
        self.animation.isRemovedOnCompletion = false
        self.animation.fillMode = .forwards
        
        self.shapeLayer.path = UIBezierPath(roundedRect: self.bounds,
                                            byRoundingCorners: [.allCorners],
                                            cornerRadii: CGSize(width: self.height * 0.25, height: self.height * 0.25)).cgPath
    
        self.shapeLayer.add(self.animation, forKey: "MyAnimation")
    }
    
    func stopRecordingAnimation() {
        self.shapeLayer.removeFromSuperlayer()
        self.shapeLayer.removeAllAnimations()
    }
}

extension FrontPreviewVideoView: CAAnimationDelegate {
    
    func animationDidStart(_ anim: CAAnimation) {
        self.animationDidStart?()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.animationDidEnd?()
    }
}

// MARK: - MTKViewDelegate

extension FrontPreviewVideoView: MTKViewDelegate {

    func draw(in view: MTKView) {
        guard let metalView = view as? MetalView else { return }

        // grab command buffer so we can encode instructions to GPU
        guard let commandBuffer = metalView.commandQueue.makeCommandBuffer() else {
            return
        }

        // grab image
        guard let ciImage = self.currentCIImage else { return }

        // ensure drawable is free and not tied in the previous drawing cycle
        guard let currentDrawable = view.currentDrawable else { return }

        // Make sure the image is full screen (Aspect fill).
        let drawSize = self.cameraView.drawableSize
        var scaleX = drawSize.width / ciImage.extent.width
        var scaleY = drawSize.height / ciImage.extent.height

        if scaleX > scaleY {
            scaleY = scaleX
        } else {
            scaleX = scaleY
        }

        let newImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

        // Render into the metal texture
        metalView.context.render(newImage,
                                 to: currentDrawable.texture,
                                 commandBuffer: commandBuffer,
                                 bounds: newImage.extent,
                                 colorSpace: CGColorSpaceCreateDeviceRGB())

        // register drawable to command buffer
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()

//        if !self.hasRenderedFaceImage {
//            Task.onMainActorAsync {
//                await Task.sleep(seconds: 1.5)
//                self.hasRenderedFaceImage = true
//                view.alpha = 1.0
//            }
//        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Delegate method not implemented.
    }
}

