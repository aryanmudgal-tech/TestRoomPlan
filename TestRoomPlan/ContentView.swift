import SwiftUI
import RoomPlan

struct ContentView: View {
    @State private var capturedRoom: CapturedRoom?
    @State private var scanDuration: TimeInterval = 0
    @State private var isScanning = false

    var body: some View {
        if let room = capturedRoom {
            ResultsView(capturedRoom: room, scanDuration: scanDuration) {
                capturedRoom = nil
                isScanning = false
            }
        } else if isScanning {
            ScanningView(
                onComplete: { room, duration in
                    capturedRoom = room
                    scanDuration = duration
                },
                onCancel: {
                    isScanning = false
                }
            )
        } else {
            startScreen
        }
    }

    // MARK: - Start Screen

    private var startScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.metering.matrix")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("RoomPlan Accuracy Tester")
                .font(.title.bold())

            Text("Scan a room to measure RoomPlan's spatial accuracy.\nWalk slowly around the room with your device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            if RoomCaptureSession.isSupported {
                Button {
                    isScanning = true
                } label: {
                    Label("Start Room Scan", systemImage: "viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Stand in the doorway when you start scanning\nso the entrance is at origin (0, 0, 0).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Label("LiDAR sensor required", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Text("RoomPlan requires an iPhone or iPad Pro with a LiDAR sensor (iPhone 12 Pro or newer).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
    }
}
