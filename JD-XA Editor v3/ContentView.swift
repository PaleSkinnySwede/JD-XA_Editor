import SwiftUI

struct ContentView: View {
    @StateObject private var midiManager = MIDIManager()
    @StateObject private var viewModel: JDXATestViewModel
    
    init() {
        let manager = MIDIManager()
        _midiManager = StateObject(wrappedValue: manager)
        _viewModel = StateObject(wrappedValue: JDXATestViewModel(midiManager: manager))
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - MIDI Device Selection
            VStack {
                GroupBox("MIDI Device") {
                    Picker("MIDI Device", selection: $viewModel.selectedDeviceID) {
                        Text("Select Device").tag(nil as Int?)
                        ForEach(viewModel.availableDevices, id: \.id) { device in
                            Text(device.name).tag(device.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                
                Spacer()
            }
            .frame(minWidth: 200)
        } detail: {
            if viewModel.selectedDeviceID != nil {
                // Main Content Area
                TabView {
                    // Test Panel
                    JDXATestView(viewModel: viewModel)
                        .tabItem {
                            Label("Test Panel", systemImage: "slider.horizontal.3")
                        }
                    
                    // Digital Panel
                    DigitalPanelView()
                        .environment(\.midiManager, midiManager)
                        .tabItem {
                            Label("Digital", systemImage: "waveform")
                        }
                }
            } else {
                // No device selected view
                VStack {
                    Image(systemName: "cable.connector")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Please select a MIDI device")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            midiManager.scanForDevices()
        }
    }
}

// Environment key for passing MIDI manager
private struct MIDIManagerKey: EnvironmentKey {
    static let defaultValue: MIDIManager? = nil
}

extension EnvironmentValues {
    var midiManager: MIDIManager? {
        get { self[MIDIManagerKey.self] }
        set { self[MIDIManagerKey.self] = newValue }
    }
}
