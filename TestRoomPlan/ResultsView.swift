import SwiftUI
import RoomPlan

struct ResultsView: View {
    let capturedRoom: CapturedRoom
    let exportData: ScanExportData
    let onNewScan: () -> Void

    @State private var selectedTab = 0
    @State private var showingShare = false

    init(capturedRoom: CapturedRoom, scanDuration: TimeInterval, onNewScan: @escaping () -> Void) {
        self.capturedRoom = capturedRoom
        self.exportData = RoomExporter.export(room: capturedRoom, scanDuration: scanDuration)
        self.onNewScan = onNewScan
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("Floor Plan").tag(0)
                    Text("Report").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if selectedTab == 0 {
                    FloorPlanView(capturedRoom: capturedRoom)
                } else {
                    reportList
                }
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("New Scan", action: onNewScan)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShare) {
                shareSheet
            }
        }
    }

    // MARK: - Report

    private var reportList: some View {
        List {
            Section("Room Dimensions") {
                Text(exportData.accuracyReport.detectedRoomSize)
                    .font(.body.monospaced())
                Text(String(format: "Scan duration: %.1f s", exportData.accuracyReport.scanDurationSeconds))
            }

            Section("Detection Counts") {
                LabeledContent("Walls", value: "\(exportData.accuracyReport.wallCount)")
                LabeledContent("Doors", value: "\(exportData.accuracyReport.doorCount)")
                LabeledContent("Windows", value: "\(exportData.accuracyReport.windowCount)")
                LabeledContent("Objects", value: "\(exportData.accuracyReport.objectCount)")
            }

            if !exportData.accuracyReport.objectInventory.isEmpty {
                Section("Object Inventory") {
                    ForEach(Array(exportData.accuracyReport.objectInventory.enumerated()), id: \.offset) { _, item in
                        Text(item)
                            .font(.caption.monospaced())
                    }
                }
            }

            if !exportData.accuracyReport.distanceReport.isEmpty {
                Section("Distance Matrix (Floor Plane)") {
                    ForEach(Array(exportData.accuracyReport.distanceReport.enumerated()), id: \.offset) { _, item in
                        Text(item)
                            .font(.caption.monospaced())
                    }
                }
            }

            Section("Wall Details") {
                ForEach(exportData.walls, id: \.index) { wall in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wall \(wall.index)")
                            .font(.subheadline.bold())
                        Text(String(format: "Position: (%.2f, %.2f, %.2f)", wall.positionX, wall.positionY, wall.positionZ))
                        Text(String(format: "Size: %.2f x %.2f m", wall.widthMeters, wall.heightMeters))
                    }
                    .font(.caption.monospaced())
                }
            }

            if !exportData.doors.isEmpty {
                Section("Door Details") {
                    ForEach(exportData.doors, id: \.index) { door in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Door \(door.index)")
                                .font(.subheadline.bold())
                            Text(String(format: "Position: (%.2f, %.2f, %.2f)", door.positionX, door.positionY, door.positionZ))
                            Text(String(format: "Size: %.2f x %.2f m", door.widthMeters, door.heightMeters))
                            if let wallIdx = door.parentWallIndex {
                                Text("Parent: Wall \(wallIdx)")
                            }
                        }
                        .font(.caption.monospaced())
                    }
                }
            }

            if !exportData.windows.isEmpty {
                Section("Window Details") {
                    ForEach(exportData.windows, id: \.index) { win in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Window \(win.index)")
                                .font(.subheadline.bold())
                            Text(String(format: "Position: (%.2f, %.2f, %.2f)", win.positionX, win.positionY, win.positionZ))
                            Text(String(format: "Size: %.2f x %.2f m", win.widthMeters, win.heightMeters))
                            if let wallIdx = win.parentWallIndex {
                                Text("Parent: Wall \(wallIdx)")
                            }
                        }
                        .font(.caption.monospaced())
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Share Sheet

    @ViewBuilder
    private var shareSheet: some View {
        let items = exportItems()
        ActivitySheet(items: items)
    }

    private func exportItems() -> [Any] {
        var items: [Any] = []

        // JSON file
        if let url = RoomExporter.saveJSON(exportData) {
            items.append(url)
        }

        // Floor plan image
        let planView = FloorPlanView(capturedRoom: capturedRoom)
            .frame(width: 800, height: 800)
            .background(Color.white)
        let renderer = ImageRenderer(content: planView)
        renderer.scale = 3
        if let image = renderer.uiImage {
            items.append(image)
        }

        return items
    }
}

// MARK: - UIActivityViewController Wrapper

struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
