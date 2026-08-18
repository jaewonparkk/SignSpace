import Foundation
import AVFoundation
import UIKit
import Combine
import MediaPipeTasksVision

final class HandTrackingService: NSObject, ObservableObject {

    // MARK: - Published UI State

    @Published var handLandmarks: [[CGPoint]] = []

    @Published var statusText: String =
        "Starting..."

    @Published var errorMessage: String?

    @Published private(set)
    var cameraDevice: AVCaptureDevice?


    // MARK: - Recording State

    @Published var isRecording: Bool = false

    @Published var recordedFrameCount: Int = 0

    @Published var latestRecording: SignMotion?


    private var recordingFrames: [SignFrame] = []

    private var recordingStartTimestamp:
        Int?


    // MARK: - Camera

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(
        label: "com.signspace.camera.session"
    )

    private let videoOutputQueue = DispatchQueue(
        label: "com.signspace.camera.video"
    )

    private var videoOutput:
        AVCaptureVideoDataOutput?

    private var isCameraConfigured =
        false


    // MARK: - Camera Rotation

    private var captureRotationCoordinator:
        AVCaptureDevice.RotationCoordinator?


    // MARK: - MediaPipe

    private var handLandmarker:
        HandLandmarker?


    // MARK: - Init

    override init() {

        super.init()

        configureHandLandmarker()

        requestCameraPermission()
    }


    // MARK: - MediaPipe Setup

    private func configureHandLandmarker() {

        guard let modelPath =
                Bundle.main.path(
                    forResource: "hand_landmarker",
                    ofType: "task"
                ) else {

            DispatchQueue.main.async {

                self.errorMessage =
                    "hand_landmarker.task was not found in the app bundle."

                self.statusText =
                    "Model missing"
            }

            return
        }


        let options =
            HandLandmarkerOptions()

        options.baseOptions.modelAssetPath =
            modelPath

        options.runningMode =
            .liveStream

        options.numHands =
            2

        options.minHandDetectionConfidence =
            0.5

        options.minHandPresenceConfidence =
            0.5

        options.minTrackingConfidence =
            0.5

        options.handLandmarkerLiveStreamDelegate =
            self


        do {

            handLandmarker =
                try HandLandmarker(
                    options: options
                )

            DispatchQueue.main.async {

                self.statusText =
                    "Hand tracker ready"
            }

        } catch {

            DispatchQueue.main.async {

                self.errorMessage =
                    "Could not create Hand Landmarker: \(error.localizedDescription)"

                self.statusText =
                    "Tracker failed"
            }
        }
    }


    // MARK: - Camera Permission

    private func requestCameraPermission() {

        switch AVCaptureDevice.authorizationStatus(
            for: .video
        ) {

        case .authorized:

            configureCamera()


        case .notDetermined:

            AVCaptureDevice.requestAccess(
                for: .video
            ) { [weak self] granted in

                guard let self else {
                    return
                }

                if granted {

                    self.configureCamera()

                } else {

                    DispatchQueue.main.async {

                        self.errorMessage =
                            "Camera permission is required to track your hands."

                        self.statusText =
                            "Camera permission denied"
                    }
                }
            }


        case .denied, .restricted:

            DispatchQueue.main.async {

                self.errorMessage =
                    "Camera permission is disabled. Enable it in Settings."

                self.statusText =
                    "Camera unavailable"
            }


        @unknown default:

            DispatchQueue.main.async {

                self.errorMessage =
                    "Unknown camera authorization state."

                self.statusText =
                    "Camera unavailable"
            }
        }
    }


    // MARK: - Camera Setup

    private func configureCamera() {

        sessionQueue.async { [weak self] in

            guard let self else {
                return
            }

            guard !self.isCameraConfigured else {
                return
            }


            self.session.beginConfiguration()

            self.session.sessionPreset =
                .high


            // MARK: Front Camera

            guard let camera =
                    AVCaptureDevice.default(
                        .builtInWideAngleCamera,
                        for: .video,
                        position: .front
                    ) else {

                self.session.commitConfiguration()

                DispatchQueue.main.async {

                    self.errorMessage =
                        "Front camera could not be found."

                    self.statusText =
                        "No front camera"
                }

                return
            }


            DispatchQueue.main.async {

                self.cameraDevice =
                    camera
            }


            self.captureRotationCoordinator =
                AVCaptureDevice.RotationCoordinator(
                    device: camera,
                    previewLayer: nil
                )


            // MARK: Camera Input

            do {

                let input =
                    try AVCaptureDeviceInput(
                        device: camera
                    )

                guard self.session.canAddInput(
                    input
                ) else {

                    self.session.commitConfiguration()

                    DispatchQueue.main.async {

                        self.errorMessage =
                            "Could not add camera input."
                    }

                    return
                }

                self.session.addInput(
                    input
                )

            } catch {

                self.session.commitConfiguration()

                DispatchQueue.main.async {

                    self.errorMessage =
                        "Camera input error: \(error.localizedDescription)"
                }

                return
            }


            // MARK: Video Output

            let output =
                AVCaptureVideoDataOutput()

            output.alwaysDiscardsLateVideoFrames =
                true

            output.videoSettings = [

                kCVPixelBufferPixelFormatTypeKey
                    as String:

                kCVPixelFormatType_32BGRA
            ]


            output.setSampleBufferDelegate(
                self,
                queue: self.videoOutputQueue
            )


            guard self.session.canAddOutput(
                output
            ) else {

                self.session.commitConfiguration()

                DispatchQueue.main.async {

                    self.errorMessage =
                        "Could not add video output."
                }

                return
            }


            self.session.addOutput(
                output
            )

            self.videoOutput =
                output


            // MARK: Capture Rotation

            if let connection =
                    output.connection(
                        with: .video
                    ) {

                if let coordinator =
                        self.captureRotationCoordinator {

                    let angle =
                        coordinator
                            .videoRotationAngleForHorizonLevelCapture

                    if connection
                        .isVideoRotationAngleSupported(
                            angle
                        ) {

                        connection.videoRotationAngle =
                            angle
                    }
                }


                // MediaPipe receives a non-mirrored frame.
                if connection
                    .isVideoMirroringSupported {

                    connection
                        .automaticallyAdjustsVideoMirroring =
                        false

                    connection.isVideoMirrored =
                        false
                }
            }


            self.session.commitConfiguration()

            self.isCameraConfigured =
                true

            self.session.startRunning()


            DispatchQueue.main.async {

                self.statusText =
                    "Show your hand"
            }
        }
    }


    // MARK: - Camera Controls

    func start() {

        sessionQueue.async { [weak self] in

            guard let self else {
                return
            }

            guard self.isCameraConfigured else {
                return
            }

            guard !self.session.isRunning else {
                return
            }

            self.session.startRunning()
        }
    }


    func stop() {

        sessionQueue.async { [weak self] in

            guard let self else {
                return
            }

            guard self.session.isRunning else {
                return
            }

            self.session.stopRunning()
        }
    }


    // MARK: - Recording Controls

    func startRecording() {

        recordingFrames.removeAll(
            keepingCapacity: true
        )

        recordingStartTimestamp =
            nil

        recordedFrameCount =
            0

        latestRecording =
            nil

        isRecording =
            true

        statusText =
            "Recording..."
    }


    func stopRecording(
        name: String = "Untitled Sign"
    ) {

        guard isRecording else {
            return
        }


        isRecording =
            false


        guard !recordingFrames.isEmpty else {

            latestRecording =
                nil

            recordedFrameCount =
                0

            statusText =
                "No hand motion captured"

            return
        }


        let motion =
            SignMotion(
                name: name,
                frames: recordingFrames
            )


        latestRecording =
            motion

        recordedFrameCount =
            recordingFrames.count

        recordingStartTimestamp =
            nil
    }


    func clearRecording() {

        latestRecording =
            nil

        recordingFrames.removeAll()

        recordedFrameCount =
            0

        recordingStartTimestamp =
            nil
    }


    // MARK: - MediaPipe Processing

    private func process(
        sampleBuffer: CMSampleBuffer
    ) {

        guard let handLandmarker else {
            return
        }


        do {

            let image =
                try MPImage(
                    sampleBuffer: sampleBuffer,
                    orientation: .up
                )


            // Camera presentation timestamps are monotonic,
            // which is what MediaPipe live-stream mode needs.

            let presentationTime =
                CMSampleBufferGetPresentationTimeStamp(
                    sampleBuffer
                )

            let seconds =
                CMTimeGetSeconds(
                    presentationTime
                )


            guard seconds.isFinite else {
                return
            }


            let timestampMilliseconds =
                Int(
                    seconds * 1000.0
                )


            try handLandmarker.detectAsync(
                image: image,
                timestampInMilliseconds:
                    timestampMilliseconds
            )

        } catch {

            DispatchQueue.main.async {

                self.errorMessage =
                    "Detection error: \(error.localizedDescription)"
            }
        }
    }
}


// MARK: - Camera Delegate

extension HandTrackingService:
    AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        process(
            sampleBuffer: sampleBuffer
        )
    }
}


// MARK: - MediaPipe Delegate

extension HandTrackingService:
    HandLandmarkerLiveStreamDelegate {

    func handLandmarker(
        _ handLandmarker: HandLandmarker,
        didFinishDetection result:
            HandLandmarkerResult?,
        timestampInMilliseconds: Int,
        error: Error?
    ) {

        // MARK: Error

        if let error {

            DispatchQueue.main.async {

                self.errorMessage =
                    "MediaPipe error: \(error.localizedDescription)"
            }

            return
        }


        // MARK: No Result

        guard let result else {

            DispatchQueue.main.async {

                self.handLandmarks =
                    []

                if !self.isRecording {

                    self.statusText =
                        "Show your hand"
                }
            }

            return
        }


        // MARK: 2D Preview Data

        let detectedHands:
            [[CGPoint]] =
            result.landmarks.map { hand in

                hand.map { landmark in

                    CGPoint(
                        x: CGFloat(
                            landmark.x
                        ),
                        y: CGFloat(
                            landmark.y
                        )
                    )
                }
            }


        // MARK: Recording Data
        //
        // Keep normalized camera coordinates AND
        // MediaPipe world coordinates.

        let capturedHands: [HandFrame] =
            zip(
                result.landmarks,
                result.worldLandmarks
            )
            .map {
                normalizedHand,
                worldHand in


                let normalizedPoints =
                    normalizedHand.map {
                        landmark in

                        LandmarkPoint(
                            x: Float(
                                landmark.x
                            ),
                            y: Float(
                                landmark.y
                            ),
                            z: Float(
                                landmark.z
                            )
                        )
                    }


                let worldPoints =
                    worldHand.map {
                        landmark in

                        LandmarkPoint(
                            x: Float(
                                landmark.x
                            ),
                            y: Float(
                                landmark.y
                            ),
                            z: Float(
                                landmark.z
                            )
                        )
                    }


                return HandFrame(
                    normalizedLandmarks:
                        normalizedPoints,
                    worldLandmarks:
                        worldPoints
                )
            }


        // MARK: UI + Recording State

        DispatchQueue.main.async {

            self.handLandmarks =
                detectedHands


            if self.isRecording {

                // First processed frame becomes t = 0.

                if self.recordingStartTimestamp ==
                    nil {

                    self.recordingStartTimestamp =
                        timestampInMilliseconds
                }


                guard let startTimestamp =
                        self.recordingStartTimestamp else {

                    return
                }


                let elapsed =
                    max(
                        0,
                        timestampInMilliseconds
                        - startTimestamp
                    )


                // Only save frames that actually
                // contain at least one hand.

                if !capturedHands.isEmpty {

                    let frame =
                        SignFrame(
                            timestampMilliseconds:
                                elapsed,
                            hands:
                                capturedHands
                        )


                    self.recordingFrames.append(
                        frame
                    )


                    self.recordedFrameCount =
                        self.recordingFrames.count
                }


                self.statusText =
                    "Recording · \(self.recordedFrameCount) frames"

                return
            }


            // MARK: Normal Tracking Status

            switch detectedHands.count {

            case 0:

                self.statusText =
                    "Show your hand"


            case 1:

                self.statusText =
                    "1 hand · 21 landmarks"


            default:

                self.statusText =
                    "\(detectedHands.count) hands · \(detectedHands.count * 21) landmarks"
            }
        }
    }
}
