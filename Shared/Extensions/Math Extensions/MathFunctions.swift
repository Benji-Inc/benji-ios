//
//  MathFunctions.swift
//  Benji
//
//  Created by Benji Dodgson on 6/30/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Rounding

/// Rounds the given value to the nearest multiple of toNearest.
func round(_ value: CGFloat, toNearest: CGFloat) -> CGFloat {
    return round(value / toNearest) * toNearest
}

// MARK: - Clamping

func clamp(_ value: Int, min: Int) -> Int {
    return (min...Int.max).clamp(value)
}

func pow(_ lhs: Int, _ rhs: Int) -> Int {
    return Int(powf(Float(lhs), Float(rhs)))
}

func clamp(_ value: CGFloat, _ min: CGFloat, _ max: CGFloat) -> CGFloat {
    return (min...max).clamp(value)
}

func clamp(_ value: CGFloat, min: CGFloat) -> CGFloat {
    return (min...CGFloat.infinity).clamp(value)
}

func clamp(_ value: CGFloat, max: CGFloat) -> CGFloat {
    return (-CGFloat.infinity...max).clamp(value)
}

// MARK: Linear Interpolation

/// Linearly interpolate between two values given a normalized value between 0 and 1
/// Example: lerp(0.2, min 1, max 3) = 1.4
func lerp(_ normalized: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    return min + normalized * (max - min)
}

/// Linearly interpolate between two values. The normalized value is clamped between 0 and 1 so
/// the result will never be outside the range of the min and max
func lerpClamped(_ normalized: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    return lerp((0...1).clamp(normalized), min: min, max: max)
}

/// Linearly interpolates along a path as defined by the key points.
/// For example, for the key points: [0, 100, 50]:
/// normalized 0 == 0
/// normalized 0.25 == 50
/// normalized 0.5 == 100
/// normalized 1 == 50
func lerp(_ normalized: CGFloat, keyPoints: [CGFloat]) -> CGFloat {
    let pointCount = keyPoints.count

    guard pointCount > 0 else { return 0 }

    let segmentLength = 1/CGFloat(pointCount - 1)
    let currentIndex = Int(normalized/segmentLength)

    guard let segmentLowerBound = keyPoints[safe: currentIndex] else { return 0 }
    guard let segmentUpperBound = keyPoints[safe: currentIndex + 1] else { return segmentLowerBound }

    let normalizedInSegment
    = normalized.truncatingRemainder(dividingBy: segmentLength)

    return lerp(normalizedInSegment/segmentLength, min: segmentLowerBound, max: segmentUpperBound)
}


// MARK: Trig Functions

let halfPi: CGFloat = CGFloat.pi * 0.5
let twoPi: CGFloat = CGFloat.pi * 2

func sin(degrees: Double) -> Double {
    return __sinpi(degrees/180.0)
}

func sin(degrees: Float) -> Float {
    return __sinpif(degrees/180.0)
}

func sin(degrees: CGFloat) -> CGFloat {
    return CGFloat(sin(degrees: degrees.native))
}
