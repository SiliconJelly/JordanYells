import Foundation
import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var currentFrame: UIImage?
    @Published var cameraPermissionGranted: Bool = false
    @Published var errorMessage: String?
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "CameraServiceQueue")
    private var lastSampleTime: Date = .distantPast
    private let sampleInterval: TimeInterval = 1.0 // 1 FPS

    override init() {
        super.init()
        checkCameraPermission()
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraPermissionGranted = true
            self.configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    if granted {
                        self.configureSession()
                    } else {
                        self.errorMessage = "Camera access is required to analyze your shots."
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.cameraPermissionGranted = false
                self.errorMessage = "Please enable camera access in Settings to use Jordan Yells."
            }
        @unknown default:
            DispatchQueue.main.async {
                self.cameraPermissionGranted = false
                self.errorMessage = "Camera access is required."
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async {
                self.errorMessage = "Camera not available on this device."
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to configure camera input."
                }
                return
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Camera configuration failed: \(error.localizedDescription)"
            }
            return
        }
        
        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            session.addOutput(videoOutput)
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Unable to configure camera output."
            }
            return
        }
        
        session.commitConfiguration()
    }

    func start() {
        guard cameraPermissionGranted else { return }
        
        if !session.isRunning {
            queue.async {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        if session.isRunning {
            queue.async {
                self.session.stopRunning()
            }
        }
    }

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        guard now.timeIntervalSince(lastSampleTime) >= sampleInterval else { return }
        lastSampleTime = now
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.currentFrame = uiImage
            }
        }
    }
} 