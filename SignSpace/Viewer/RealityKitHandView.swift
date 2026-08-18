import SwiftUI
import RealityKit
import UIKit

struct RealityKitHandView:
    UIViewRepresentable {

    let motion: SignMotion

    let currentFrameIndex: Int

    let yaw: Float

    let pitch: Float

    let zoom: Float

    let showTrail: Bool


    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {

        Coordinator()
    }


    // MARK: - Make View

    func makeUIView(
        context: Context
    ) -> ARView {

        let arView =
            ARView(
                frame: .zero,
                cameraMode: .nonAR,
                automaticallyConfigureSession: false
            )


        arView.environment.background =
            .color(
                UIColor(
                    red: 0.055,
                    green: 0.055,
                    blue: 0.065,
                    alpha: 1.0
                )
            )


        // MARK: Root Anchor

        let anchor =
            AnchorEntity()


        anchor.addChild(
            context.coordinator
                .renderer
                .root
        )


        // MARK: Virtual Camera

        let camera =
            PerspectiveCamera()


        camera.look(
            at: SIMD3<Float>(
                0,
                0,
                0
            ),
            from: SIMD3<Float>(
                0,
                0,
                0.72
            ),
            relativeTo: nil
        )


        anchor.addChild(
            camera
        )


        arView.scene.addAnchor(
            anchor
        )


        context.coordinator.anchor =
            anchor

        context.coordinator.camera =
            camera


        updateRenderer(
            context:
                context
        )


        return arView
    }


    // MARK: - Update View

    func updateUIView(
        _ uiView: ARView,
        context: Context
    ) {

        updateRenderer(
            context:
                context
        )
    }


    // MARK: - Renderer Update

    private func updateRenderer(
        context: Context
    ) {

        guard !motion.frames.isEmpty else {
            return
        }


        let safeIndex =
            min(
                max(
                    currentFrameIndex,
                    0
                ),
                motion.frames.count - 1
            )


        let frame =
            motion.frames[
                safeIndex
            ]


        context.coordinator.renderer.update(
            with: frame
        )


        context.coordinator.renderer.updateTrail(
            motion: motion,
            through: safeIndex,
            isVisible: showTrail
        )


        context.coordinator.renderer
            .setViewTransform(
                yaw: yaw,
                pitch: pitch,
                zoom: zoom
            )
    }


    // MARK: - Coordinator

    final class Coordinator {

        let renderer =
            HandSkeletonRenderer()


        var anchor:
            AnchorEntity?


        var camera:
            PerspectiveCamera?
    }
}
