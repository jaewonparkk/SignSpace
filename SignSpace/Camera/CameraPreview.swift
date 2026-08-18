import SwiftUI
import AVFoundation
import UIKit

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession
    let cameraDevice: AVCaptureDevice?

    func makeUIView(context: Context) -> CameraPreviewUIView {

        let view = CameraPreviewUIView()

        view.session = session
        view.cameraDevice = cameraDevice

        return view
    }

    func updateUIView(
        _ uiView: CameraPreviewUIView,
        context: Context
    ) {

        uiView.session = session
        uiView.cameraDevice = cameraDevice
    }
}


final class CameraPreviewUIView: UIView {

    // MARK: - Preview Layer

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {

        guard let previewLayer =
                layer as? AVCaptureVideoPreviewLayer else {

            fatalError(
                "CameraPreviewUIView must use AVCaptureVideoPreviewLayer."
            )
        }

        return previewLayer
    }


    // MARK: - Session

    var session: AVCaptureSession? {

        get {
            previewLayer.session
        }

        set {

            previewLayer.session = newValue

            previewLayer.videoGravity = .resizeAspectFill
        }
    }


    // MARK: - Camera

    var cameraDevice: AVCaptureDevice? {

        didSet {

            guard oldValue !== cameraDevice else {
                return
            }

            configureRotationCoordinator()
        }
    }


    // MARK: - Rotation

    private var rotationCoordinator:
        AVCaptureDevice.RotationCoordinator?

    private var rotationObservation:
        NSKeyValueObservation?


    private func configureRotationCoordinator() {

        rotationObservation = nil
        rotationCoordinator = nil

        guard let cameraDevice else {
            return
        }

        let coordinator =
            AVCaptureDevice.RotationCoordinator(
                device: cameraDevice,
                previewLayer: previewLayer
            )

        rotationCoordinator = coordinator

        rotationObservation = coordinator.observe(
            \.videoRotationAngleForHorizonLevelPreview,
            options: [.initial, .new]
        ) { [weak self] coordinator, _ in

            DispatchQueue.main.async {

                self?.applyRotation(
                    coordinator.videoRotationAngleForHorizonLevelPreview
                )
            }
        }
    }


    private func applyRotation(
        _ angle: CGFloat
    ) {

        guard let connection =
                previewLayer.connection else {
            return
        }

        guard connection.isVideoRotationAngleSupported(
            angle
        ) else {
            return
        }

        connection.videoRotationAngle = angle

        // Selfie-style mirror
        if connection.isVideoMirroringSupported {

            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }


    // MARK: - Layout

    override func layoutSubviews() {

        super.layoutSubviews()

        if let rotationCoordinator {

            applyRotation(
                rotationCoordinator
                    .videoRotationAngleForHorizonLevelPreview
            )
        }
    }
}
