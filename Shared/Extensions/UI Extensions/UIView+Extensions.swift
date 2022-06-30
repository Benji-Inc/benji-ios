//
//  UIView+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

extension UIView: Selectable {

    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self),
                                                owner: nil,
                                                options: nil)!.first as! T
    }

    var isVisible: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }

    func makeRound(masksToBounds: Bool = true) {
        self.layer.masksToBounds = masksToBounds
        self.layer.cornerRadius = self.halfHeight
    }

    func roundCorners() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Theme.cornerRadius
    }

    func round(corners: UIRectCorner, size: CGSize) {
        let maskPath1 = UIBezierPath(roundedRect: self.bounds,
                                     byRoundingCorners: corners,
                                     cornerRadii: size)
        let maskLayer1 = CAShapeLayer()
        maskLayer1.frame = self.bounds
        maskLayer1.path = maskPath1.cgPath
        self.layer.mask = maskLayer1
    }

    func removeAllSubviews() {
        for view in subviews {
            view.removeFromSuperview()
        }
    }

    func findInSubviews(condition: (UIView) -> Bool) -> UIView? {
        for view in subviews {
            if condition(view) {
                return view
            } else {
                if let result = view.findInSubviews(condition: condition) {
                    return result
                }
            }
        }

        return nil
    }

    func showShadow(withOffset offset: CGFloat,
                    opacity: Float = 0.3,
                    radius: CGFloat = 10,
                    color: UIColor = .black) {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = CGSize(width: 0, height: offset)
        self.layer.shadowRadius = radius
        self.layer.masksToBounds = false
    }

    func hideShadow() {
        self.layer.shadowOpacity = 0.0
    }

    func contains(_ other: UIView) -> Bool {
        let otherBounds = other.convert(other.bounds, to: nil)
        let selfBounds = self.convert(self.bounds, to: nil)

        return selfBounds.contains(otherBounds)
    }

    func currentFirstResponder() -> UIResponder? {
        if self.isFirstResponder {
            return self
        }

        for view in self.subviews {
            if let responder = view.currentFirstResponder() {
                return responder
            }
        }

        return nil
    }

    func set(backgroundColor: ThemeColor) {
        self.backgroundColor = backgroundColor.color.resolvedColor(with: self.traitCollection)
    }

    func moveTo(_ x: CGFloat, _ y: CGFloat) {
        self.frame = CGRect(x: x, y: y, width: self.width, height: self.height)
    }

    func moveTo(_ origin: CGPoint) {
        self.moveTo(origin.x, origin.y)
    }

    func subviews<T: UIView>(type : T.Type) -> [T] {
        var matchingViews: [T] = []

        for view in self.subviews {
            if let view = view as? T {
                matchingViews.append(view)
            }
        }

        return matchingViews
    }

    func renderSnapshot() -> UIView {
        let shadowOpacity = self.layer.shadowOpacity
        self.layer.shadowOpacity = 0 // avoid capturing shadow bits in bounds

        let snapshot = UIImageView(image: UIGraphicsImageRenderer(bounds: bounds).image { context in
            self.layer.render(in: context.cgContext)
        })
        self.layer.shadowOpacity = shadowOpacity

        if let shadowPath = self.layer.shadowPath {
            snapshot.layer.shadowPath = shadowPath
            snapshot.layer.shadowColor = layer.shadowColor
            snapshot.layer.shadowOffset = layer.shadowOffset
            snapshot.layer.shadowRadius = layer.shadowRadius
            snapshot.layer.shadowOpacity = layer.shadowOpacity
        }
        return snapshot
    }
}

