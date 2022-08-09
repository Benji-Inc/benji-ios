//
//  PiPRecordingViewController+Costs.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation

struct ExceededCaptureSessionCosts: OptionSet {
    let rawValue: Int
    
    static let systemPressureCost = ExceededCaptureSessionCosts(rawValue: 1 << 0)
    static let hardwareCost = ExceededCaptureSessionCosts(rawValue: 1 << 1)
}

/*
 Helps adjust the cameras to not overload the system or hardware.
 */

extension PiPRecordingViewController {
    
    func checkSystemCost() {
        var exceededSessionCosts: ExceededCaptureSessionCosts = []
        
        if self.session.systemPressureCost > 1.0 {
            exceededSessionCosts.insert(.systemPressureCost)
        }
        
        if self.session.hardwareCost > 1.0 {
            exceededSessionCosts.insert(.hardwareCost)
        }
        
        switch exceededSessionCosts {
            
        case .systemPressureCost:
            // Choice #1: Reduce front camera resolution
            if self.reduceResolutionForCamera(.front) {
                self.checkSystemCost()
            }
                
            // Choice 2: Reduce the number of video input ports
            else if self.reduceVideoInputPorts() {
                self.checkSystemCost()
            }
                
            // Choice #3: Reduce back camera resolution
            else if self.reduceResolutionForCamera(.back) {
                self.checkSystemCost()
            }
                
            // Choice #4: Reduce front camera frame rate
            else if self.reduceFrameRateForCamera(.front) {
                self.checkSystemCost()
            }
                
            // Choice #5: Reduce frame rate of back camera
            else if self.reduceFrameRateForCamera(.back) {
                self.checkSystemCost()
            } else {
                print("Unable to further reduce session cost.")
            }
            
        case .hardwareCost:
            // Choice #1: Reduce front camera resolution
            if self.reduceResolutionForCamera(.front) {
                self.checkSystemCost()
            }
                
            // Choice 2: Reduce back camera resolution
            else if self.reduceResolutionForCamera(.back) {
                self.checkSystemCost()
            }
                
            // Choice #3: Reduce front camera frame rate
            else if self.reduceFrameRateForCamera(.front) {
                self.checkSystemCost()
            }
                
            // Choice #4: Reduce back camera frame rate
            else if self.reduceFrameRateForCamera(.back) {
                self.checkSystemCost()
            } else {
                print("Unable to further reduce session cost.")
            }
            
        case [.systemPressureCost, .hardwareCost]:
            // Choice #1: Reduce front camera resolution
            if self.reduceResolutionForCamera(.front) {
                self.checkSystemCost()
            }
                
            // Choice #2: Reduce back camera resolution
            else if self.reduceResolutionForCamera(.back) {
                self.checkSystemCost()
            }
                
            // Choice #3: Reduce front camera frame rate
            else if self.reduceFrameRateForCamera(.front) {
                self.checkSystemCost()
            }
                
            // Choice #4: Reduce back camera frame rate
            else if self.reduceFrameRateForCamera(.back) {
                self.checkSystemCost()
            } else {
                print("Unable to further reduce session cost.")
            }
            
        default:
            break
        }
    }
    
    private func reduceResolutionForCamera(_ position: AVCaptureDevice.Position) -> Bool {
        for connection in self.session.connections {
            for inputPort in connection.inputPorts {
                if inputPort.mediaType == .video && inputPort.sourceDevicePosition == position {
                    guard let videoDeviceInput: AVCaptureDeviceInput = inputPort.input as? AVCaptureDeviceInput else {
                        return false
                    }
                    
                    var dims: CMVideoDimensions
                    
                    var width: Int32
                    var height: Int32
                    var activeWidth: Int32
                    var activeHeight: Int32
                    
                    dims = CMVideoFormatDescriptionGetDimensions(videoDeviceInput.device.activeFormat.formatDescription)
                    activeWidth = dims.width
                    activeHeight = dims.height
                    
                    if ( activeHeight <= 480 ) && ( activeWidth <= 640 ) {
                        return false
                    }
                    
                    let formats = videoDeviceInput.device.formats
                    if let formatIndex = formats.firstIndex(of: videoDeviceInput.device.activeFormat) {
                        
                        for index in (0..<formatIndex).reversed() {
                            let format = videoDeviceInput.device.formats[index]
                            if format.isMultiCamSupported {
                                dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                                width = dims.width
                                height = dims.height
                                
                                if width < activeWidth || height < activeHeight {
                                    do {
                                        try videoDeviceInput.device.lockForConfiguration()
                                        videoDeviceInput.device.activeFormat = format
                                        
                                        videoDeviceInput.device.unlockForConfiguration()
                                        
                                        print("reduced width = \(width), reduced height = \(height)")
                                        
                                        return true
                                    } catch {
                                        print("Could not lock device for configuration: \(error)")
                                        
                                        return false
                                    }
                                    
                                } else {
                                    continue
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    private func reduceVideoInputPorts () -> Bool {
        var newConnection: AVCaptureConnection
        var result = false
        
        for connection in self.session.connections {
            for inputPort in connection.inputPorts where inputPort.sourceDeviceType == .builtInDualCamera {
                print("Changing input from dual to single camera")
                
                guard let videoDeviceInput: AVCaptureDeviceInput = inputPort.input as? AVCaptureDeviceInput,
                    let wideCameraPort: AVCaptureInput.Port = videoDeviceInput.ports(for: .video,
                                                                                     sourceDeviceType: .builtInWideAngleCamera,
                                                                                     sourceDevicePosition: videoDeviceInput.device.position).first else {
                                                                                        return false
                }
                
                if let previewLayer = connection.videoPreviewLayer {
                    newConnection = AVCaptureConnection(inputPort: wideCameraPort, videoPreviewLayer: previewLayer)
                } else if let savedOutput = connection.output {
                    newConnection = AVCaptureConnection(inputPorts: [wideCameraPort], output: savedOutput)
                } else {
                    continue
                }
                self.session.beginConfiguration()
                
                self.session.removeConnection(connection)
                
                if self.session.canAddConnection(newConnection) {
                    self.session.addConnection(newConnection)
                    
                    self.session.commitConfiguration()
                    result = true
                } else {
                    print("Could not add new connection to the session")
                    self.session.commitConfiguration()
                    return false
                }
            }
        }
        return result
    }
    
    func reduceFrameRateForCamera(_ position: AVCaptureDevice.Position) -> Bool {
        for connection in self.session.connections {
            for inputPort in connection.inputPorts {
                
                if inputPort.mediaType == .video && inputPort.sourceDevicePosition == position {
                    guard let videoDeviceInput: AVCaptureDeviceInput = inputPort.input as? AVCaptureDeviceInput else {
                        return false
                    }
                    let activeMinFrameDuration = videoDeviceInput.device.activeVideoMinFrameDuration
                    var activeMaxFrameRate: Double = Double(activeMinFrameDuration.timescale) / Double(activeMinFrameDuration.value)
                    activeMaxFrameRate -= 10.0
                    
                    // Cap the device frame rate to this new max, never allowing it to go below 15 fps
                    if activeMaxFrameRate >= 15.0 {
                        do {
                            try videoDeviceInput.device.lockForConfiguration()
                            videoDeviceInput.videoMinFrameDurationOverride = CMTimeMake(value: 1, timescale: Int32(activeMaxFrameRate))
                            
                            videoDeviceInput.device.unlockForConfiguration()
                            
                            print("reduced fps = \(activeMaxFrameRate)")
                            
                            return true
                        } catch {
                            print("Could not lock device for configuration: \(error)")
                            return false
                        }
                    } else {
                        return false
                    }
                }
            }
        }
        
        return false
    }
    
}
