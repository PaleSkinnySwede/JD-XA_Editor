import SwiftUI

/// What the detail area shows, picked in the sidebar.
enum EditorDestination: Hashable {
    case digital(part: Int)
    case testPanel
}

struct ContentView: View {
    @StateObject private var midiManager: MIDIManager
    @StateObject private var viewModel: JDXATestViewModel
    @StateObject private var digitalStore: DigitalEditorStore
    @State private var selection: EditorDestination? = .digital(part: 1)

    init() {
        let manager = MIDIManager()
        _midiManager = StateObject(wrappedValue: manager)
        _viewModel = StateObject(wrappedValue: JDXATestViewModel(midiManager: manager))
        _digitalStore = StateObject(wrappedValue: DigitalEditorStore(midiManager: manager))
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Digital Synth") {
                    ForEach(DigitalEditorStore.parts, id: \.self) { part in
                        Label("Part \(part)", systemImage: "\(part).square.fill")
                            .tag(EditorDestination.digital(part: part))
                    }
                }

                Section("Tools") {
                    Label("MIDI Test Panel", systemImage: "wrench.and.screwdriver")
                        .tag(EditorDestination.testPanel)
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                ConnectionPanel(viewModel: viewModel, midiManager: midiManager)
                    .padding(10)
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 300)
        } detail: {
            switch selection {
            case .digital(let part):
                DigitalPanelView(partNumber: part, store: digitalStore)
                    // Fresh PCM sheet and drag states per part
                    .id(part)
            case .testPanel:
                JDXATestView(viewModel: viewModel)
            case nil:
                Text("Choose a part in the sidebar")
                    .foregroundColor(ThemeColors.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ThemeColors.background)
            }
        }
        .frame(minWidth: 1020, minHeight: 680)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Connection panel

/// MIDI output picker and status, pinned to the bottom of the sidebar.
private struct ConnectionPanel: View {
    @ObservedObject var viewModel: JDXATestViewModel
    @ObservedObject var midiManager: MIDIManager

    private var isConnected: Bool { viewModel.selectedDeviceID != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? ThemeColors.connected : ThemeColors.disconnected)
                    .frame(width: 8, height: 8)
                    .shadow(color: (isConnected ? ThemeColors.connected : ThemeColors.disconnected).opacity(0.6), radius: 3)
                Text(isConnected ? "MIDI output ready" : "Offline")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button {
                    midiManager.scanForDevices()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Rescan MIDI devices")
            }

            Picker("MIDI Output", selection: $viewModel.selectedDeviceID) {
                Text("No device").tag(nil as Int?)
                ForEach(viewModel.availableDevices) { device in
                    Text(device.name).tag(device.id as Int?)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            if isConnected {
                Button {
                    viewModel.sendDeviceInquiry()
                } label: {
                    Label("Send Device Inquiry", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.small)
                .help("Ask the synth to identify itself. The reply shows in the MIDI Test Panel log.")
            } else {
                Text("Choose your JD-XA to send changes. You can edit without one.")
                    .font(.system(size: 11))
                    .foregroundColor(ThemeColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ThemeColors.stroke)
        )
    }
}
