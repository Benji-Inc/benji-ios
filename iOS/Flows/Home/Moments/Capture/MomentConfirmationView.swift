//
//  MomentConfirmationView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentConfirmationView: BaseView {
    
    let circle = BaseView()
    let progressView = UIProgressView()
    let label = ThemeLabel(font: .display)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.circle)

        if let window = UIWindow.topWindow() {
            self.circle.squaredSize = window.height * 1.25
            self.circle.layer.cornerRadius = circle.halfHeight
        }
        
        self.circle.set(backgroundColor: .D1)
        self.circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        self.circle.alpha = 0
        
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.alpha = 0

        self.addSubview(self.progressView)
        self.progressView.progressTintColor = ThemeColor.D6.color
        self.progressView.alpha = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.circle.centerOnXAndY()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
        
        self.progressView.width = self.width * 0.25
        self.progressView.centerOnX()
        self.progressView.match(.top, to: .bottom, of: self.label, offset: .standard)
    }
    
    func uploadMoment(from recording: PiPRecording, caption: String?) async {
        await UIView.awaitSpringAnimation(with: .slow, animations: {
            self.circle.transform = .identity
            self.circle.alpha = 1.0 
        })
        
        self.label.setText("Uploading...")
        self.label.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        self.layoutNow()
        
        await UIView.awaitSpringAnimation(with: .fast, animations: {
            self.label.alpha = 1.0
            self.label.transform = .identity
            self.progressView.alpha = 1.0
        })
        
        do {
            async let creation: () = try self.createMoment(from: recording, caption: caption)
            async let progress: () = UIView.awaitAnimation(with: .slow) {
                self.progressView.setProgress(1.0, animated: true)
            }
            
            let _ = try await [creation, progress]
                        
            await UIView.awaitSpringAnimation(with: .standard, animations: {
                self.label.alpha = 0
                self.label.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                self.progressView.alpha = 0
            })
            
            self.label.setText("Success! 🎉")
            self.layoutNow()
            
            await UIView.awaitSpringAnimation(with: .standard, animations: {
                self.label.transform = .identity
                self.label.alpha = 1.0
            })
                        
        } catch {
            
            await UIView.awaitSpringAnimation(with: .fast, animations: {
                self.label.alpha = 0
                self.label.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                self.progressView.alpha = 0
            })
            
            self.label.setText("Error")
            self.layoutNow()
            
            await UIView.awaitAnimation(with: .standard, animations: {
                self.label.transform = .identity
                self.label.alpha = 1.0
            })
            
            logError(error)
        }
    }
    
    private func createMoment(from recording: PiPRecording, caption: String?) async throws {
        do {
            try await MomentsStore.shared.createMoment(from: recording, caption: caption)
        } catch {
            throw ClientError.error(error: error)
        }
    }
}
