import Foundation
import AVFoundation
import UIKit
import Combine
import MediaPipeTasksVision


final class HandTrackingService:
    NSObject,
    ObservableObject {

    // MARK: - Published UI State

    @Published var handLandmarks:
        [[CGPoint]] = []

    @Published var detectedHandedness:
        [Handedness] = []

    @Published var statusText:
        String = "Starting..."

    @Published var errorMessage:
        String?

    @Published private(set)
    var cameraDevice:
        AVCaptureDevice?


    // MARK: - Recording State

    @Published var isRecording:
        Bool = false

    @Published var recordedFrameCount:
        Int = 0

    @Published var latestRecording:
        SignMotion?


    private var recordingFrames:
        [SignFrame] = []

    private var recordingStartTimestamp:
        Int?


    // MARK: - Camera

    let session =
        AVCaptureSession()


    private let sessionQueue =
        DispatchQueue(
            label:
                "com.signspace.camera.session"
        )


    private let videoOutputQueue =
        DispatchQueue(
            label:
                "com.signspace.camera.video"
        )


    private var videoOutput:
        AVCaptureVideoDataOutput?


    private var isCameraConfigured =
        false


    private var hasStartedPreparing =
        false


    // MARK: - Rotation

    private var captureRotationCoordinator:
        AVCaptureDevice.RotationCoordinator?


    // MARK: - MediaPipe

    private var handLandmarker:
        HandLandmarker?


    /*
     Our MediaPipe input is intentionally
     NON-MIRRORED.

     The preview itself is mirrored separately
     inside CameraPreview.swift.

     MediaPipe handedness classification assumes
     selfie-style mirrored input, so we swap
     Left <-> Right after classification.
     */

    private let mediaPipeInputIsMirrored =
        false


    // MARK: - Init

    override init() {

        super.init()
    }


    // MARK: - MediaPipe Setup

    private func configureHandLandmarker() {

        guard let modelPath =
                Bundle.main.path(
                    forResource:
                        "hand_landmarker",
                    ofType:
                        "task"
                )
        else {

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


        // Support two-hand signs.

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
                    options:
                        options
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

        switch
            AVCaptureDevice
                .authorizationStatus(
                    for:
                        .video
                ) {

        case .authorized:

            configureCamera()


        case .notDetermined:

            AVCaptureDevice.requestAccess(
                for:
                    .video
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


        case .denied,
             .restricted:

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

        sessionQueue.async {
            [weak self] in

            guard let self else {
                return
            }


            guard
                !self.isCameraConfigured
            else {
                return
            }


            self.session
                .beginConfiguration()


            self.session.sessionPreset =
                .high


            // MARK: Front Camera

            guard let camera =
                    AVCaptureDevice.default(
                        .builtInWideAngleCamera,
                        for:
                            .video,
                        position:
                            .front
                    )
            else {

                self.session
                    .commitConfiguration()


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
                AVCaptureDevice
                    .RotationCoordinator(
                        device:
                            camera,
                        previewLayer:
                            nil
                    )


            // MARK: Input

            do {

                let input =
                    try AVCaptureDeviceInput(
                        device:
                            camera
                    )


                guard
                    self.session
                        .canAddInput(
                            input
                        )
                else {

                    self.session
                        .commitConfiguration()


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

                self.session
                    .commitConfiguration()


                DispatchQueue.main.async {

                    self.errorMessage =
                        "Camera input error: \(error.localizedDescription)"
                }

                return
            }


            // MARK: Output

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
                queue:
                    self.videoOutputQueue
            )


            guard
                self.session
                    .canAddOutput(
                        output
                    )
            else {

                self.session
                    .commitConfiguration()


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
                    with:
                        .video
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

                        connection
                            .videoRotationAngle =
                            angle
                    }
                }


                /*
                 IMPORTANT

                 The buffer going into MediaPipe
                 remains NON-MIRRORED.

                 CameraPreview.swift mirrors the
                 visible selfie preview separately.
                 */

                if connection
                    .isVideoMirroringSupported {

                    connection
                        .automaticallyAdjustsVideoMirroring =
                        false


                    connection
                        .isVideoMirrored =
                        false
                }
            }


            self.session
                .commitConfiguration()


            self.isCameraConfigured =
                true


            self.session
                .startRunning()


            DispatchQueue.main.async {

                self.statusText =
                    "Show your hand"
            }
        }
    }


    // MARK: - Camera Controls

    func start() {

        if !hasStartedPreparing {

            hasStartedPreparing =
                true


            // Defer camera and model work until a camera screen is actually
            // shown. Model construction stays on the processing queue.
            videoOutputQueue.async { [weak self] in
                self?.configureHandLandmarker()
            }


            requestCameraPermission()
        }

        sessionQueue.async {
            [weak self] in

            guard let self else {
                return
            }


            guard
                self.isCameraConfigured
            else {
                return
            }


            guard
                !self.session.isRunning
            else {
                return
            }


            self.session
                .startRunning()
        }
    }


    func stop() {

        sessionQueue.async {
            [weak self] in

            guard let self else {
                return
            }


            guard
                self.session.isRunning
            else {
                return
            }


            self.session
                .stopRunning()
        }
    }


    // MARK: - Recording Controls

    func startRecording() {

        recordingFrames
            .removeAll(
                keepingCapacity:
                    true
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
        name: String =
            "Untitled Sign"
    ) {

        guard
            isRecording
        else {
            return
        }


        isRecording =
            false


        guard
            !recordingFrames.isEmpty
        else {

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
                name:
                    name,
                frames:
                    recordingFrames
            )


        latestRecording =
            motion


        recordedFrameCount =
            recordingFrames.count


        recordingStartTimestamp =
            nil


        updateNormalStatus()
    }


    func clearRecording() {

        latestRecording =
            nil


        recordingFrames
            .removeAll()


        recordedFrameCount =
            0


        recordingStartTimestamp =
            nil
    }


    // MARK: - MediaPipe Processing

    private func process(
        sampleBuffer:
            CMSampleBuffer
    ) {

        guard let handLandmarker else {
            return
        }


        do {

            let image =
                try MPImage(
                    sampleBuffer:
                        sampleBuffer,
                    orientation:
                        .up
                )


            /*
             MediaPipe live-stream timestamps
             must increase monotonically.

             CMSampleBuffer's presentation time
             gives us exactly that.
             */

            let presentationTime =
                CMSampleBufferGetPresentationTimeStamp(
                    sampleBuffer
                )


            let seconds =
                CMTimeGetSeconds(
                    presentationTime
                )


            guard
                seconds.isFinite
            else {
                return
            }


            let timestampMilliseconds =
                Int(
                    seconds
                    * 1000.0
                )


            try handLandmarker
                .detectAsync(
                    image:
                        image,
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


    // MARK: - Handedness

    private func normalizedHandedness(
        rawLabel: String?
    ) -> Handedness {

        guard
            let rawLabel
        else {

            return .unknown
        }


        let rawHand:
            Handedness


        switch rawLabel
            .lowercased() {

        case "left":

            rawHand =
                .left


        case "right":

            rawHand =
                .right


        default:

            rawHand =
                .unknown
        }


        guard
            !mediaPipeInputIsMirrored
        else {

            return rawHand
        }


        // MediaPipe assumes mirrored/selfie input.
        // Our inference buffer is not mirrored.

        switch rawHand {

        case .left:

            return .right


        case .right:

            return .left


        case .unknown:

            return .unknown
        }
    }


    // MARK: - Status

    private func updateNormalStatus() {

        let hands =
            detectedHandedness


        switch hands.count {

        case 0:

            statusText =
                "Show your hand"


        case 1:

            statusText =
                "\(hands[0].displayName) hand · 21 landmarks"


        default:

            let labels =
                hands
                    .map {
                        $0.displayName
                    }
                    .joined(
                        separator:
                            " + "
                    )


            statusText =
                "\(labels) · \(hands.count * 21) landmarks"
        }
    }
}


// MARK: - Camera Delegate

extension HandTrackingService:
    AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output:
            AVCaptureOutput,
        didOutput sampleBuffer:
            CMSampleBuffer,
        from connection:
            AVCaptureConnection
    ) {

        process(
            sampleBuffer:
                sampleBuffer
        )
    }
}


// MARK: - MediaPipe Delegate

extension HandTrackingService:
    HandLandmarkerLiveStreamDelegate {

    func handLandmarker(
        _ handLandmarker:
            HandLandmarker,
        didFinishDetection result:
            HandLandmarkerResult?,
        timestampInMilliseconds:
            Int,
        error:
            Error?
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


                self.detectedHandedness =
                    []


                if !self.isRecording {

                    self.statusText =
                        "Show your hand"
                }
            }

            return
        }


        // MARK: Build Stable Hands

        struct DetectedHandBundle {

            let previewPoints:
                [CGPoint]

            let handFrame:
                HandFrame

            let wristX:
                Float
        }


        let detectedCount =
            min(
                result.landmarks.count,
                result.worldLandmarks.count
            )


        var bundles:
            [DetectedHandBundle] = []


        if detectedCount > 0 {

            for index in 0..<detectedCount {

                let normalizedHand =
                    result.landmarks[
                        index
                    ]


                let worldHand =
                    result.worldLandmarks[
                        index
                    ]


                // MARK: Handedness Classification

                let category =
                    index <
                    result.handedness.count
                    ? result.handedness[
                        index
                    ].first
                    : nil


                let handedness =
                    normalizedHandedness(
                        rawLabel:
                            category?
                                .categoryName
                    )


                let confidence =
                    category?
                        .score
                    ?? 0


                // MARK: Preview Points

                let previewPoints =
                    normalizedHand.map {
                        landmark in

                        CGPoint(
                            x:
                                CGFloat(
                                    landmark.x
                                ),
                            y:
                                CGFloat(
                                    landmark.y
                                )
                        )
                    }


                // MARK: Normalized Points

                let normalizedPoints =
                    normalizedHand.map {
                        landmark in

                        LandmarkPoint(
                            x:
                                Float(
                                    landmark.x
                                ),
                            y:
                                Float(
                                    landmark.y
                                ),
                            z:
                                Float(
                                    landmark.z
                                )
                        )
                    }


                // MARK: World Points

                let worldPoints =
                    worldHand.map {
                        landmark in

                        LandmarkPoint(
                            x:
                                Float(
                                    landmark.x
                                ),
                            y:
                                Float(
                                    landmark.y
                                ),
                            z:
                                Float(
                                    landmark.z
                                )
                        )
                    }


                let handFrame =
                    HandFrame(
                        normalizedLandmarks:
                            normalizedPoints,
                        worldLandmarks:
                            worldPoints,
                        handedness:
                            handedness,
                        handednessConfidence:
                            confidence
                    )


                let wristX =
                    normalizedPoints
                        .first?
                        .x
                    ?? 0.5


                bundles.append(
                    DetectedHandBundle(
                        previewPoints:
                            previewPoints,
                        handFrame:
                            handFrame,
                        wristX:
                            wristX
                    )
                )
            }
        }


        /*
         THE IMPORTANT PART

         Every frame now gets a deterministic order:

         Left
         Right
         Unknown

         So MediaPipe changing detection order
         between frames no longer swaps hands.
         */

        bundles.sort {

            let leftOrder =
                $0.handFrame
                    .handedness
                    .sortOrder


            let rightOrder =
                $1.handFrame
                    .handedness
                    .sortOrder


            if leftOrder != rightOrder {

                return
                    leftOrder
                    < rightOrder
            }


            // Stable fallback for unknown / equal labels.

            return
                $0.wristX
                < $1.wristX
        }


        let detectedHands =
            bundles.map {
                $0.previewPoints
            }


        let capturedHands =
            bundles.map {
                $0.handFrame
            }


        let handednessList =
            bundles.map {
                $0.handFrame
                    .handedness
            }


        // MARK: UI + Recording

        DispatchQueue.main.async {

            self.handLandmarks =
                detectedHands


            self.detectedHandedness =
                handednessList


            // MARK: Recording

            if self.isRecording {

                if self.recordingStartTimestamp ==
                    nil {

                    self.recordingStartTimestamp =
                        timestampInMilliseconds
                }


                guard
                    let startTimestamp =
                        self.recordingStartTimestamp
                else {
                    return
                }


                let elapsed =
                    max(
                        0,
                        timestampInMilliseconds
                        - startTimestamp
                    )


                if !capturedHands.isEmpty {

                    let frame =
                        SignFrame(
                            timestampMilliseconds:
                                elapsed,
                            hands:
                                capturedHands
                        )


                    self.recordingFrames
                        .append(
                            frame
                        )


                    self.recordedFrameCount =
                        self.recordingFrames
                            .count
                }


                let names =
                    handednessList
                        .map {
                            $0.displayName
                        }
                        .joined(
                            separator:
                                " + "
                        )


                if names.isEmpty {

                    self.statusText =
                        "Recording · \(self.recordedFrameCount) frames"

                } else {

                    self.statusText =
                        "Recording \(names) · \(self.recordedFrameCount) frames"
                }


                return
            }


            // MARK: Normal Tracking

            self.updateNormalStatus()
        }
    }
}
