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
func lerp(_ normalized: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
    return start + normalized * (end - start)
}

/// Linearly interpolate between two values. The normalized value is clamped between 0 and 1 so
/// the result will never be outside the range of the start and end
func lerpClamped(_ normalized: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
    return lerp((0...1).clamp(normalized), start: start, end: end)
}

/// Linearly interpolates along a range as defined by the key points.
/// For example, for the key points: [0, 100, 50]:
/// normalized 0 == 0
/// normalized 0.25 == 50
/// normalized 0.5 == 100
/// normalized 1 == 50
func lerp(_ normalized: CGFloat, keyPoints: [CGFloat]) -> CGFloat {
    let pointCount = keyPoints.count

    guard pointCount > 0 else { return 0 }

    guard normalized > 0 else { return keyPoints.first ?? 0 }

    let segmentLength = 1/CGFloat(pointCount - 1)
    let currentIndex = Int(normalized/segmentLength)

    guard let segmentLowerBound = keyPoints[safe: currentIndex] else {
        return keyPoints.last ?? 0
    }
    guard let segmentUpperBound = keyPoints[safe: currentIndex + 1] else { return segmentLowerBound }

    let normalizedInSegment
    = normalized.truncatingRemainder(dividingBy: segmentLength)

    return lerp(normalizedInSegment/segmentLength, start: segmentLowerBound, end: segmentUpperBound)
}

func lerpClamped(_ normalized: CGFloat, keyPoints: [CGFloat]) -> CGFloat {
    return lerp((0...1).clamp(normalized), keyPoints: keyPoints)
}

// MARK: - CGPoint Interpolation

func lerp(_ normalized: CGFloat, start: CGPoint, end: CGPoint) -> CGPoint {
    return CGPoint(x: start.x + normalized * (end.x - start.x),
                   y: start.y + normalized * (end.y - start.y))
}

/// Linearly interpolates along a 2D path as defined by the key points.
/// For example, for the key points: [(0,0), (0,50), (100,100)]:
/// normalized 0 == (0,0)
/// normalized 0.5 == (0,50)
/// normalized 0.75 == (50,75)
/// normalized 1 == (100, 100)
func lerp(_ normalized: CGFloat, keyPoints: [CGPoint]) -> CGPoint {
    let pointCount = keyPoints.count

    // There needs to be at least two keypoints to form a path.
    guard pointCount > 1 else { return keyPoints.first ?? .zero }

    // Normalized values outside of the 0 to 1 range are clamped.
    guard normalized > 0 else { return keyPoints.first ?? .zero }
    guard normalized < 1 else { return keyPoints.last ?? .zero }

    // Determine how much of the normalized value each path segment takes up.
    let segmentLength = 1/CGFloat(pointCount - 1)
    // Determine which segment we're currently on.
    let currentIndex = Int(normalized/segmentLength)

    guard let segmentLowerBound = keyPoints[safe: currentIndex] else {
        return keyPoints.first ?? .zero
    }
    guard let segmentUpperBound = keyPoints[safe: currentIndex + 1] else { return segmentLowerBound }

    // Figure out how far we've travelled within the current segment
    let normalizedInSegment
    = normalized.truncatingRemainder(dividingBy: segmentLength)

    return lerp(normalizedInSegment/segmentLength, start: segmentLowerBound, end: segmentUpperBound)
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
