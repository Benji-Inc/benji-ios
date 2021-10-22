//
//  ConfettiView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConfettiView: View {

    var emitter = CAEmitterLayer()

    var colors: [Color] = [
        Color.darkGray,
        Color.lightGray,
        Color.textColor]

    var velocities:[Int] = [
        100,
        90,
        150,
        200
    ]

    var spins: [Double] = [
        -Double.pi * 2,
        -Double.pi * 1.5,
        Double.pi,
        Double.pi * 1.5
    ]

    func startConfetti(with timer: TimeInterval? = nil) {
        // Set the start time to the current time so that the confetti doesn't appear all at one
        self.emitter.beginTime = CACurrentMediaTime()
        self.emitter.emitterPosition = CGPoint(x: self.halfWidth, y: -10)
        self.emitter.emitterShape = CAEmitterLayerEmitterShape.line
        self.emitter.emitterSize = CGSize(width: self.width, height: 2.0)
        self.emitter.emitterCells = self.generateEmitterCells()
        self.layer.addSublayer(self.emitter)

        if let stopTime = timer {
            delay(stopTime) {
                self.stopConfetti()
            }
        }
    }

    func stopConfetti() {
        self.emitter.birthRate = 0
    }

    private func generateEmitterCells() -> [CAEmitterCell] {
        var cells:[CAEmitterCell] = [CAEmitterCell]()
        for index in 0..<16 {

            let cell = CAEmitterCell()

            cell.birthRate = 2.0
            cell.lifetime = 14.0
            cell.lifetimeRange = 0
            cell.velocity = CGFloat(self.getRandomVelocity())
            cell.velocityRange = 0
            cell.emissionLongitude = CGFloat(Double.pi)
            cell.emissionRange = 0.5
            cell.spin = CGFloat(self.getRandomSpin())
            cell.spinRange = 0
            cell.color = self.getNextColor(i: index)
            cell.contents = self.getNextImage(i: index)
            cell.scaleRange = 0.3
            cell.scale = 0.2
            cell.alphaRange = 1.0

            cells.append(cell)
        }

        return cells
    }

    private func getRandomVelocity() -> Int {
        return self.velocities[self.getRandomNumber()]
    }

    private func getRandomSpin() -> Double {
        return self.spins[self.getRandomNumber()]
    }

    private func getRandomNumber() -> Int {
        return Int(arc4random_uniform(4))
    }

    private func getNextColor(i:Int) -> CGColor {
        if i <= 4 {
            return self.colors[0].color.cgColor
        } else if i <= 8 {
            return self.colors[1].color.cgColor
        } else  {
            return self.colors[2].color.cgColor
        }
    }

    private func getNextImage(i: Int) -> CGImage {
        return UIImage(named: "leaf")!.cgImage!
    }
}
