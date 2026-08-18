import SwiftUI
import AVFoundation
import UIKit

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(
        context: Context
    ) -> CameraPreviewUIView {

        let view = CameraPreviewUIView()

        view.session = session

        return view
    }

    func updateUIView(
        _ uiView: CameraPreviewUIView,
        context: Context
    ) {

        uiView.session = session
        uiView.configurePreviewConnection()
    }
}


final class CameraPreviewUIView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }


    private var previewLayer: AVCaptureVideoPreviewLayer {

        guard let layer =
                layer as? AVCaptureVideoPreviewLayer else {

            fatalError(
                "CameraPreviewUIView must use AVCaptureVideoPreviewLayer."
            )
        }

        return layer
    }


    var session: AVCaptureSession? {

        get {
            previewLayer.session
        }

        set {

            previewLayer.session = newValue
            previewLayer.videoGravity = .resizeAspectFill

            DispatchQueue.main.async {
                self.configurePreviewConnection()
            }
        }
    }


    override func layoutSubviews() {
        super.layoutSubviews()

        configurePreviewConnection()
    }


    func configurePreviewConnection() {

        guard let connection =
                previewLayer.connection else {
            return
        }


        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }


        // Mirror only what the user sees,
        // just like the normal selfie camera.
        if connection.isVideoMirroringSupported {

            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }
}
