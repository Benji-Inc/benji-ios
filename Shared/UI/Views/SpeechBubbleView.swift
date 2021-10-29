//
//  SpeechBubbleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/29/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A view that has a rounded rectangular "speech bubble" background.
 /// The bubble has two parts: The bubble itself, and a triangular "tail" positioned on one of four sides.
 /// Subviews should be added to the contentView property.
 class SpeechBubbleView: View {

     enum TailOrientation {
         case up
         case down
         case left
         case right
     }

     /// The direction that the speech bubble's tail is pointing.
     var orientation: TailOrientation {
         didSet {
             self.setNeedsLayout()
         }
     }

     /// The color of the speech bubble.
     var bubbleColor: UIColor? {
         get {
             guard let cgColor = self.bubbleLayer.fillColor else { return nil }
             return UIColor(cgColor: cgColor)
         }
         set {
             self.bubbleLayer.fillColor = newValue?.cgColor
         }
     }

     /// The color of the border around the speech bubble.
     var borderColor: UIColor? {
         get {
             guard let cgColor = self.bubbleLayer.strokeColor else { return nil }
             return UIColor(cgColor: cgColor)
         }
         set {
             self.bubbleLayer.strokeColor = newValue?.cgColor
         }
     }

     /// The distance from the base of the tail to the point.
     var tailLength: CGFloat = 7 {
         didSet { self.setNeedsLayout() }
     }
     /// The length of the base of the tail. In other words, side of the tail flush with bubble.
     var tailBaseLength: CGFloat = 14 {
         didSet { self.setNeedsLayout() }
     }
     /// Describes how much the bubble layer needs to be pushed in to make room for the tail.
     var bubbleFrame: CGRect {
         let topSide = self.orientation == .up ? self.tailLength : 0
         let leftSide = self.orientation == .left ? self.tailLength : 0
         let bottomSide = self.orientation == .down ? self.height - self.tailLength : self.height
         let rightSide = self.orientation == .right ? self.width - self.tailLength : self.width

         return CGRect(x: leftSide,
                       y: topSide,
                       width: rightSide - leftSide,
                       height: bottomSide - topSide)
     }

     /// A view to contain subviews you want positioned inside the bubble. This view matches the frame of the bubble, excluding the tail.
     let contentView = View()
     /// The layer for drawing the speech bubble background.
     private let bubbleLayer = CAShapeLayer()

     init(orientation: TailOrientation, bubbleColor: UIColor? = nil, borderColor: UIColor? = nil) {
         self.orientation = orientation

         super.init()

         self.bubbleColor = bubbleColor
         self.borderColor = borderColor
     }

     required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }

     override func initializeSubviews() {
         super.initializeSubviews()

         self.layer.addSublayer(self.bubbleLayer)
         self.bubbleLayer.fillColor = UIColor.gray.cgColor
         self.bubbleLayer.lineWidth = 2

         self.addSubview(self.contentView)
     }

     override func layoutSubviews() {
         super.layoutSubviews()

         // Get content size
         // Get insets/tail lenght
         // Draw bubble path with content size and insets
         // Set x,y of content view
         // Set size of self
        // self.setSize()

         self.updateBubblePath()

         // Match the content view to the area of the bubble.
         self.contentView.frame = self.bubbleFrame
     }

     #warning("Leaving this as a placeholder")

//     private func setSize() {
//         var newFrame: CGRect = .zero
//
//         self.subviews.forEach { view in
//             if view is TextView {
//                 newFrame = newFrame.union(view.frame)
//             }
//         }
//
//         switch self.orientation {
//         case .up:
//             <#code#>
//         case .down:
//             <#code#>
//         case .left:
//             <#code#>
//         case .right:
//             <#code#>
//         }
//
//         newFrame.size.height += 10 + self.tailLength
//         newFrame.size.width += 10
//
//         self.size = newFrame.size
//     }

     /// Draws a path for the bubble and applies it to the bubble layer.
     private func updateBubblePath() {
         let cornerRadius: CGFloat = Theme.cornerRadius
         let bubbleFrame = self.bubbleFrame
         let tailBaseLength = self.tailBaseLength

         let path = CGMutablePath()

         // Top left corner
         path.move(to: CGPoint(x: bubbleFrame.left, y: bubbleFrame.top + cornerRadius))
         path.addArc(tangent1End: CGPoint(x: bubbleFrame.left, y: bubbleFrame.top),
                     tangent2End: CGPoint(x: bubbleFrame.left + cornerRadius, y: bubbleFrame.top),
                     radius: cornerRadius)

         // Up facing tail
         if self.orientation == .up {
             path.addLine(to: CGPoint(x: self.halfWidth - tailBaseLength.half, y: bubbleFrame.top))
             path.addLine(to: CGPoint(x: self.halfWidth, y: 0))
             path.addLine(to: CGPoint(x: self.halfWidth + tailBaseLength.half, y: bubbleFrame.top))
         }

         // Top right corner
         path.addLine(to: CGPoint(x: bubbleFrame.right - cornerRadius, y: bubbleFrame.top))
         path.addArc(tangent1End: CGPoint(x: bubbleFrame.right, y: bubbleFrame.top),
                     tangent2End: CGPoint(x: bubbleFrame.right, y: bubbleFrame.top + cornerRadius),
                     radius: cornerRadius)

         // Right facing tail
         if self.orientation == .right {
             path.addLine(to: CGPoint(x: bubbleFrame.right, y: self.halfHeight - tailBaseLength.half))
             path.addLine(to: CGPoint(x: self.width, y: self.halfHeight))
             path.addLine(to: CGPoint(x: bubbleFrame.right, y: self.halfHeight + tailBaseLength.half))
         }

         // Bottom right corner
         path.addLine(to: CGPoint(x: bubbleFrame.right, y: bubbleFrame.bottom - cornerRadius))
         path.addArc(tangent1End: CGPoint(x: bubbleFrame.right, y: bubbleFrame.bottom),
                     tangent2End: CGPoint(x: bubbleFrame.right - cornerRadius, y: bubbleFrame.bottom),
                     radius: cornerRadius)

         // Down facing tail
         if self.orientation == .down {
             path.addLine(to: CGPoint(x: self.halfWidth + tailBaseLength.half, y: bubbleFrame.bottom))
             path.addLine(to: CGPoint(x: self.halfWidth, y: self.height))
             path.addLine(to: CGPoint(x: self.halfWidth - tailBaseLength.half, y: bubbleFrame.bottom))
         }

         // Bottom left corner
         path.addLine(to: CGPoint(x: bubbleFrame.left + cornerRadius, y: bubbleFrame.bottom))
         path.addArc(tangent1End: CGPoint(x: bubbleFrame.left, y: bubbleFrame.bottom),
                     tangent2End: CGPoint(x: bubbleFrame.left, y: bubbleFrame.bottom - cornerRadius),
                     radius: cornerRadius)

         // Left facing tail
         if self.orientation == .left {
             path.addLine(to: CGPoint(x: bubbleFrame.left, y: self.halfHeight + tailBaseLength.half))
             path.addLine(to: CGPoint(x: 0, y: self.halfHeight))
             path.addLine(to: CGPoint(x: bubbleFrame.left, y: self.halfHeight - tailBaseLength.half))
         }

         path.closeSubpath()

         self.bubbleLayer.path = path
     }
 }
