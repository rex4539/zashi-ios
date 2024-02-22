//
//  CaptureDeviceLiveKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 11.11.2022.
//

import AVFoundation
import ComposableArchitecture

extension CaptureDeviceClient: DependencyKey {
    public static let liveValue = Self(
        isAuthorized: {
            AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        },
        isTorchAvailable: {
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                return false
            }

            return videoCaptureDevice.hasTorch
        },
        torch: { isTorchOn in
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                throw CaptureDeviceClientError.captureDevice
            }
            
            guard videoCaptureDevice.hasTorch else {
                throw CaptureDeviceClientError.torchUnavailable
            }

            do {
                try videoCaptureDevice.lockForConfiguration()
                videoCaptureDevice.torchMode = isTorchOn ? .on : .off
                videoCaptureDevice.unlockForConfiguration()
            } catch {
                throw CaptureDeviceClientError.lockForConfiguration
            }
        }
    )
}
