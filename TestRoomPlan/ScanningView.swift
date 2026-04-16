import SwiftUI
import RoomPlan

struct ScanningView: View {
    let onComplete: (CapturedRoom, TimeInterval) -> Void
    let onCancel: () -> Void

    @State private var scanStartTime = Date()

    var body: some View {
        RoomCaptureViewRepresentable(
            onComplete: { room in
                let duration = Date().timeIntervalSince(scanStartTime)
                onComplete(room, duration)
            },
            onCancel: onCancel
        )
        .ignoresSafeArea()
    }
}

// MARK: - UIViewRepresentable

struct RoomCaptureViewRepresentable: UIViewRepresentable {
    let onComplete: (CapturedRoom) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onCancel: onCancel)
    }

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView()
        view.delegate = context.coordinator
        let config = RoomCaptureSession.Configuration()
        view.captureSession.run(configuration: config)
        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}

    static func dismantleUIView(_ uiView: RoomCaptureView, coordinator: Coordinator) {
        uiView.captureSession.stop()
    }

    // MARK: Coordinator

    class Coordinator: NSObject, RoomCaptureViewDelegate {
        let onComplete: (CapturedRoom) -> Void
        let onCancel: () -> Void

        init(onComplete: @escaping (CapturedRoom) -> Void, onCancel: @escaping () -> Void) {
            self.onComplete = onComplete
            self.onCancel = onCancel
        }

        nonisolated func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (any Error)?) -> Bool {
            if error != nil {
                Task { @MainActor in self.onCancel() }
                return false
            }
            return true
        }

        nonisolated func captureView(didPresent processedResult: CapturedRoom, error: (any Error)?) {
            Task { @MainActor in
                if error == nil {
                    self.onComplete(processedResult)
                } else {
                    self.onCancel()
                }
            }
        }
    }
}
