import SwiftUI
import RealityKit
import UIKit

struct RealityKitComparisonView: UIViewRepresentable {

    let targetMotion: SignMotion
    let userMotion: SignMotion

    let progress: Double

    let yaw: Float
    let pitch: Float
    let zoom: Float


    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }


    // MARK: - Make View

    func makeUIView(
        context: Context
    ) -> ARView {

        let arView = ARView(
            frame: .zero,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )

        arView.environment.background = .color(
            UIColor(
                red: 0.055,
                green: 0.055,
                blue: 0.065,
                alpha: 1.0
            )
        )


        // MARK: Root Anchor

        let anchor = AnchorEntity()

        anchor.addChild(
            context.coordinator.renderer.root
        )


        // MARK: Camera

        let camera = PerspectiveCamera()

        camera.look(
            at: SIMD3<Float>(
                0,
                0,
                0
            ),
            from: SIMD3<Float>(
                0,
                0,
                0.70
            ),
            relativeTo: nil
        )

        anchor.addChild(camera)

        arView.scene.addAnchor(anchor)


        context.coordinator.anchor = anchor
        context.coordinator.camera = camera


        updateRenderer(
            context: context
        )


        return arView
    }


    // MARK: - Update View

    func updateUIView(
        _ uiView: ARView,
        context: Context
    ) {

        updateRenderer(
            context: context
        )
    }


    // MARK: - Renderer Update

    private func updateRenderer(
        context: Context
    ) {

        guard
            !targetMotion.frames.isEmpty,
            !userMotion.frames.isEmpty
        else {
            return
        }


        let safeProgress = min(
            max(
                progress,
                0
            ),
            1
        )


        // MARK: Target Frame

        let targetIndex = Int(
            (
                Double(
                    targetMotion.frames.count - 1
                )
                * safeProgress
            )
            .rounded()
        )


        // MARK: User Frame

        let userIndex = Int(
            (
                Double(
                    userMotion.frames.count - 1
                )
                * safeProgress
            )
            .rounded()
        )


        let targetFrame =
            targetMotion.frames[
                targetIndex
            ]


        let userFrame =
            userMotion.frames[
                userIndex
            ]


        // First frame used as movement origin.

        let targetReference =
            targetMotion
                .frames
                .first?
                .hands
                .first


        let userReference =
            userMotion
                .frames
                .first?
                .hands
                .first


        context.coordinator.renderer.update(
            targetFrame: targetFrame,
            userFrame: userFrame,
            targetReference: targetReference,
            userReference: userReference
        )


        context.coordinator.renderer.setViewTransform(
            yaw: yaw,
            pitch: pitch,
            zoom: zoom
        )
    }


    // MARK: - Coordinator

    final class Coordinator {

        let renderer =
            ComparisonHandRenderer()

        var anchor:
            AnchorEntity?

        var camera:
            PerspectiveCamera?
    }
}
