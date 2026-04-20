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
