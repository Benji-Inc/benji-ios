//
//  VideoView.swift
//  Jibber
//
//  Created by Martin Young on 6/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import AVFoundation

class VideoView: BaseView {
    
    var shouldPlay: Bool = false {
        didSet {
            guard let player = self.playerLayer.player else { return }
            
            if self.shouldPlay, !player.isPlaying {
                player.playImmediately(atRate: 1.0 )
            } else if !self.shouldPlay, player.isPlaying {
                player.pause()
            }
        }
    }

    var videoURL: URL? {
        didSet {
            self.updatePlayer(with: self.videoURL)
        }
    }

    let playerLayer = AVPlayerLayer(player: nil)
    /// An object that keeps looping the video back to the beginning.
    private var looper: AVPlayerLooper?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        NotificationCenter.default.publisher(for: AVPlayer.rateDidChangeNotification)
            .filter({ notification in
                if let player = notification.object as? AVPlayer,
                   player === self.playerLayer.player {
                    return true
                }
                
                return false
            }).mainSink { [unowned self] (value) in
                guard let player = value.object as? AVQueuePlayer else { return }
                
                switch player.status {
                case .unknown:
                    break
                case .readyToPlay:
                    switch player.timeControlStatus {
                    case .paused, .waitingToPlayAtSpecifiedRate:
  
                        guard let reason = player.reasonForWaitingToPlay else { return }
                                                
                        switch reason {
                        case .evaluatingBufferingRate:
                            logDebug("evaluatingBufferingRate")
                        case .toMinimizeStalls:
                            logDebug("toMinimizeStalls")
                        case .noItemToPlay:
                            logDebug("noItemToPlay")
                        default:
                            logDebug("Unknown \(reason)")
                        }

                    case .playing:
                        break
                    @unknown default:
                        break
                    }
                case .failed:
                    break
                @unknown default:
                    break
                }
                
            }.store(in: &self.cancellables)
        
        self.layer.addSublayer(self.playerLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.playerLayer.frame = self.bounds
    }

    private func updatePlayer(with url: URL?) {
        guard let videoURL = url else {
            return
        }
        
        Task {
            let asset = AVAsset(url: videoURL)
            let tracks = try? await asset.loadTracks(withMediaType: .video) // Loads from cache if available

            guard let videoAsset = tracks?.first?.asset else { return }
            
            let videoItem = AVPlayerItem(asset: videoAsset)
            
            if let player = self.playerLayer.player {
                player.replaceCurrentItem(with: videoItem)
            } else {
                let player = AVQueuePlayer(items: [videoItem])
                player.automaticallyWaitsToMinimizeStalling = false
                self.playerLayer.player = player
            }
            
            guard let player = self.playerLayer.player as? AVQueuePlayer else { return }
            
            self.looper = AVPlayerLooper(player: player, templateItem: videoItem)
            
            if self.shouldPlay {
                player.playImmediately(atRate: 1.0)
            }
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}
