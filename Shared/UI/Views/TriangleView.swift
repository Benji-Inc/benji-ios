//
//  SpikeView.swift
//  Jibber
//
//  Created by Martin Young on 10/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

private let imageResolution: CGFloat = 100

/// A view that displays a triangle within its bounds.
class TriangleView: View {

    enum Orientation {
        case up
        case down
        case left
        case right
    }

    /// The direction that the triangle should be pointing.
    var orientation: Orientation {
        didSet { self.updateSpikeImage() }
    }
    var spikeColor: UIColor? = Color.lightGray.color {
        didSet { self.updateSpikeImage() }
    }

    private let triangleImageView = UIImageView()

    init(orientation: Orientation) {
        self.orientation = orientation

        super.init()

        self.size = CGSize(width: 10, height: 10)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.triangleImageView)
        self.triangleImageView.contentMode = .scaleToFill
        self.updateSpikeImage()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.triangleImageView.expandToSuperviewSize()
    }

    private func updateSpikeImage() {
        let path = UIBezierPath()
        path.lineJoinStyle = .miter

        switch self.orientation {
        case .up:
            path.move(to: CGPoint(x: 0, y: imageResolution))
            path.addLine(to: CGPoint(x: imageResolution, y: imageResolution))
            path.addLine(to: CGPoint(x: imageResolution.half, y: 0))
            path.addLine(to: CGPoint(x: 0, y: imageResolution))
        case .down:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: imageResolution, y: 0))
            path.addLine(to: CGPoint(x: imageResolution.half, y: imageResolution))
            path.addLine(to: CGPoint(x: 0, y: 0))
        case .left:
            path.move(to: CGPoint(x: imageResolution, y: 0))
            path.addLine(to: CGPoint(x: imageResolution, y: imageResolution))
            path.addLine(to: CGPoint(x: 0, y: imageResolution.half))
            path.addLine(to: CGPoint(x: imageResolution, y: 0))
        case .right:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: imageResolution, y: imageResolution.half))
            path.addLine(to: CGPoint(x: 0, y: imageResolution))
            path.addLine(to: CGPoint(x: 0, y: 0))
        }

        let image = path.image(withStrokeColor: self.spikeColor ?? UIColor.clear,
                               fillColor: self.spikeColor ?? UIColor.clear)
        self.triangleImageView.image = image
    }
}

fileprivate extension UIBezierPath {

    func image(withStrokeColor strokeColor: UIColor, fillColor: UIColor) -> UIImage? {
        let bounds = self.bounds

        UIGraphicsBeginImageContextWithOptions(CGSize(width: bounds.size.width + self.lineWidth * 2,
                                                      height: bounds.size.width + self.lineWidth * 2),
                                               false,
                                               UIScreen.main.scale)

        let context = UIGraphicsGetCurrentContext()!

        // offset the draw to allow the line thickness to not get clipped
        context.translateBy(x: self.lineWidth, y: self.lineWidth);

        strokeColor.setStroke()
        fillColor.setFill()

        self.fill()
        self.stroke()

        let result = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext();

        return result
    }

}
