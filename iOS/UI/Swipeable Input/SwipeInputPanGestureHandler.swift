//
//  SwipeInputPanGestureRecognizer.swift
//  Jibber
//
//  Created by Martin Young on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie

class SwipeInputPanGestureHandler {

    let inputView: SwipeableInputAccessoryView

    init(inputView: SwipeableInputAccessoryView) {
        self.inputView = inputView
    }

    /// An object to give the user touch feedback when performing certain actions.
    private var impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private var previewView: PreviewMessageView?
    /// The center point of the preview view when the pan started.
    private var initialPreviewCenter: CGPoint?
    /// How far the preview view can be dragged left or right.
    private let maxXOffset: CGFloat = 40
    /// If true, the preview view is currently in the drop zone.
    private var isPreviewInDropZone = false

    func handle(pan: UIPanGestureRecognizer) {
        guard self.shouldHandlePan() else { return }

        let panOffset = pan.translation(in: nil)

        switch pan.state {
        case .possible:
            break
        case .began:
            self.handlePanBegan()
        case .changed:
            self.handlePanChanged(withOffset: panOffset)
        case .ended:
            self.handlePanEnded(withOffset: panOffset)
        case .cancelled, .failed:
            self.handlePanFailed()
        @unknown default:
            break
        }
    }

    private func shouldHandlePan() -> Bool {
        // Only handle pans if the user has input a sendable message.
        let object = SendableObject(kind: self.inputView.currentMessageKind,
                                    context: self.inputView.currentContext,
                                    emotion: self.inputView.currentEmotion,
                                    previousMessage: self.inputView.editableMessage)
        return object.isSendable
    }

    private func handlePanBegan() {
        let object = SendableObject(kind: self.inputView.currentMessageKind,
                                    context: self.inputView.currentContext,
                                    emotion: self.inputView.currentEmotion,
                                    previousMessage: self.inputView.editableMessage)
        self.inputView.sendable = object

        // Hide the input area. The preview view will take its place during the pan.
        self.inputView.inputContainerView.alpha = 0

        // Stop any swipe hint animations if they're playing.
        self.inputView.updateSwipeHint(shouldPlay: false)

        // Initialize the preview view for the user to drag up the screen.
        self.previewView = PreviewMessageView(orientation: .down,
                                              bubbleColor: self.inputView.currentContext.color.color)
        self.previewView?.frame = self.inputView.inputContainerView.frame
        self.previewView?.messageKind = self.inputView.currentMessageKind
        self.previewView?.showShadow(withOffset: 8)
        self.inputView.addSubview(self.previewView!)

        self.initialPreviewCenter = self.previewView?.center

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.inputView.deliveryTypeView.alpha = 0.0
            self.inputView.emotionView.alpha = 0.0
        }
        
        self.animatePreviewScale(shouldScale: true)
        
        self.inputView.delegate?.swipeableInputAccessoryDidBeginSwipe(self.inputView)
    }
    
    private func animatePreviewScale(shouldScale: Bool, completion: CompletionOptional = nil) {
        let transform: CGAffineTransform = shouldScale ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        UIView.animate(withDuration: Theme.animationDurationStandard,
                       delay: 0.0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 5, options: .curveEaseInOut) {
            self.previewView?.transform = transform
        } completion: { _ in
            completion?()
        }
    }

    private func handlePanChanged(withOffset panOffset: CGPoint) {
        self.updatePreviewViewPosition(withOffset: panOffset)

        guard let sendable = self.inputView.sendable, let previewView = self.previewView else { return }

        self.inputView.delegate?.swipeableInputAccessory(self.inputView,
                                               didUpdatePreviewFrame: previewView.frame,
                                               for: sendable)
    }

    private func handlePanEnded(withOffset panOffset: CGPoint) {
        self.updatePreviewViewPosition(withOffset: panOffset)

        var sendableWillBeSent = false

        if let sendable = self.inputView.sendable,
           let previewView = self.previewView,
           let delegate = self.inputView.delegate {

            sendableWillBeSent = delegate.swipeableInputAccessory(self.inputView,
                                                                  triggeredSendFor: sendable,
                                                                  withPreviewFrame: previewView.frame)
        }

        self.resetPreviewAndInputViews(didSend: sendableWillBeSent)

        self.inputView.delegate?.swipeableInputAccessory(self.inputView,
                                                         didFinishSwipeSendingSendable: sendableWillBeSent)
    }

    private func handlePanFailed() {
        self.inputView.inputContainerView.alpha = 1
        self.previewView?.removeFromSuperview()
        self.inputView.delegate?.swipeableInputAccessory(self.inputView,
                                                         didFinishSwipeSendingSendable: false)
    }

    /// Updates the position of the preview view based on the provided pan gesture offset. This function ensures that preview view's origin
    /// is kept within bounds defined by max X and Y offset.
    private func updatePreviewViewPosition(withOffset panOffset: CGPoint) {
        guard let initialCenter = self.initialPreviewCenter,
              let previewView = self.previewView else { return }

        let offsetX = clamp(panOffset.x, -self.maxXOffset, self.maxXOffset)

        var previewCenter = initialCenter + CGPoint(x: offsetX, y: panOffset.y)

        // As the user drags further up, gravitate the preview view toward the drop zone.
        let dropZoneCenter = self.inputView.dropZoneFrame.center
        let xGravityRange: CGFloat = 30
        // Range along y axis from the drop zone center within which we start gravitating the preview
        let yGravityRange: CGFloat = self.inputView.dropZoneFrame.height

        // Vector pointing from the current preview center to the drop zone center.
        var gravityVector = CGVector(startPoint: previewCenter, endPoint: dropZoneCenter)

        // The closer to the drop zone, the stronger the gravity should be.
        let gravityFactorX = lerpClamped(abs(previewCenter.x - dropZoneCenter.x)/xGravityRange,
                                         keyPoints: [1, 0.95, 0.85, 0.5, 0])
        let gravityFactorY = lerpClamped(abs(previewCenter.y - dropZoneCenter.y)/yGravityRange,
                                        keyPoints: [1, 0.95, 0.85, 0.7, 0])
        gravityVector = CGVector(dx: gravityVector.dx * gravityFactorX,
                                 dy: gravityVector.dy * gravityFactorY)

        // Adjust the preview's center with the gravity vector.
        previewCenter = CGPoint(x: previewCenter.x + gravityVector.dx,
                                y: previewCenter.y + gravityVector.dy)

        previewView.center = previewCenter

        // Provide haptic and visual feedback when the message is ready to send.
        let distanceToDropZone = CGVector(startPoint: previewCenter, endPoint: dropZoneCenter).magnitude
        if distanceToDropZone < self.inputView.dropZoneFrame.height * 0.5 {
            if !self.isPreviewInDropZone {
                self.animatePreviewScale(shouldScale: false)
                previewView.setBubbleColor(ThemeColor.D1.color, animated: true)
                previewView.textView.setTextColor(.T3)
                self.impactFeedback.impactOccurred()
            }
            self.isPreviewInDropZone = true
        } else {
            if self.isPreviewInDropZone {
                self.animatePreviewScale(shouldScale: true)
                previewView.setBubbleColor(ThemeColor.B1.color, animated: true)
                // Apple bug where the trait collection for all subviews is dark, even though it should be light.
                // So we have to access the window to get the correct trait. 
                if let window = UIWindow.topWindow(), window.traitCollection.userInterfaceStyle == .light {
                    previewView.textView.setTextColor(.B3)
                } else {
                    previewView.textView.setTextColor(.T1)
                }
            }
            self.isPreviewInDropZone = false
        }
    }

    private func resetPreviewAndInputViews(didSend: Bool) {
        if didSend {
            self.impactFeedback.impactOccurred()
            self.animatePreviewScale(shouldScale: false) { [unowned self] in
                UIView.animate(withDuration: Theme.animationDurationStandard) {
                    self.previewView?.alpha = 0
                } completion: { completed in
                    self.previewView?.removeFromSuperview()
                    self.inputView.resetInputViews()
                }
            }
            
        } else {
            // If the user didn't swipe far enough to send a message, animate the preview view back
            // to where it started, then reveal the text view to allow for input again.
            self.inputView.inputContainerView.layer.shadowOpacity = 0.0
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                guard let initialOrigin = self.initialPreviewCenter else { return }
                self.previewView?.center = initialOrigin
                self.previewView?.transform = .identity
            } completion: { completed in
                UIView.animate(withDuration: Theme.animationDurationStandard) {
                    self.inputView.inputContainerView.alpha = 1
                } completion: { completed in
                    self.inputView.inputContainerView.layer.shadowOpacity = 0.3
                    self.previewView?.removeFromSuperview()
                }
            }
        }

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.inputView.deliveryTypeView.alpha = 1.0
            self.inputView.emotionView.alpha = 1.0
        }
    }
}
