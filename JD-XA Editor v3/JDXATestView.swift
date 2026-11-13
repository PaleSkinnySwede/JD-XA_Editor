import SwiftUI
import CoreMIDI
import Combine

// MARK: - JD-XA Test View
class JDXATestViewModel: ObservableObject {
    let sysEx = JDXASysEx()
    let midiManager: MIDIManager
    
    @Published var selectedDeviceID: Int? {
        didSet {
            midiManager.selectedDeviceID = selectedDeviceID
        }
    }
    @Published var availableDevices: [(id: Int, name: String)] = []
    @Published var messageLog: [String] = []
    @Published var selectedBasicWaveform: DOscWaveform = .saw
    @Published var selectedWaveformVariation: WaveformVariation = .a
    @Published var selectedSuperNaturalWave: Int = 1
    @Published var reverbType: Double = 0
    @Published var hpfCutoff: Double = 64
    
    init(midiManager: MIDIManager) {
        self.midiManager = midiManager
        
        // Observe MIDI manager's device list
        midiManager.$availableDevices
            .assign(to: &$availableDevices)
            
        // Observe selected device
        $selectedDeviceID
            .sink { id in
                midiManager.selectedDeviceID = id
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func sendDeviceInquiry() {
        let message = sysEx.createDeviceInquiry()
        midiManager.sendPacket(message)
        logMessage("Sent Device Inquiry: \(sysEx.messageToHexString(message))")
    }
    
    func changeReverbType() {
        let message = sysEx.changeProgramReverbType(to: UInt8(reverbType))
        midiManager.sendPacket(message)
        logMessage("Changed Reverb Type: \(sysEx.messageToHexString(message))")
    }
    
    func changeHPFCutoff() {
        let message = sysEx.changeDigitalHpfCutoff(to: UInt8(hpfCutoff))
        midiManager.sendPacket(message)
        logMessage("Changed HPF Cutoff: \(sysEx.messageToHexString(message))")
    }
    
    func logMessage(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = Date().timeIntervalSince1970
            let logEntry = "\(timestamp): \(message)"
            self.messageLog.insert(logEntry, at: 0)
            if self.messageLog.count > 100 {
                self.messageLog = Array(self.messageLog.prefix(100))
            }
        }
    }
}

// MARK: - Struct
struct JDXATestView: View {
    @StateObject var viewModel: JDXATestViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // MIDI Device Selection
            GroupBox("MIDI Device") {
                Picker("MIDI Device", selection: $viewModel.selectedDeviceID) {
                    Text("Select Device").tag(nil as Int?)
                    ForEach(viewModel.availableDevices, id: \.id) { device in
                        Text(device.name).tag(device.id as Int?)
                    }
                }
                .pickerStyle(.menu)
                
                Button("Send Device Inquiry") {
                    viewModel.sendDeviceInquiry()
                }
                .disabled(viewModel.selectedDeviceID == nil)
            }
            .padding()
            
            // Parameter Controls
            GroupBox("Parameter Test") {
                VStack(spacing: 15) {
                    // Digital OSC Waveform Section
                    GroupBox("Digital OSC Waveforms") {
                        VStack(alignment: .leading, spacing: 10) {
                            // Basic Waveforms
                            VStack(alignment: .leading) {
                                Text("Basic Waveforms")
                                    .font(.caption)
                                HStack {
                                    Picker("Basic Waveform", selection: $viewModel.selectedBasicWaveform) {
                                        ForEach(DOscWaveform.allCases, id: \.self) { waveform in
                                            Text(waveform.name).tag(waveform)
                                        }
                                    }
                                    
                                    Picker("Variation", selection: $viewModel.selectedWaveformVariation) {
                                        ForEach(WaveformVariation.allCases, id: \.self) { variation in
                                            Text(variation.name).tag(variation)
                                        }
                                    }
                                    .frame(width: 70)  // Make the variation picker more compact
                                }
                                Button("Send Basic Waveform") {
                                    let messages = viewModel.sysEx.changeDigitalOscWaveform(
                                        to: viewModel.selectedBasicWaveform,
                                        variation: viewModel.selectedWaveformVariation
                                    )
                                    
                                    // Send first message (set basic waveform)
                                    viewModel.midiManager.sendPacket(messages[0])
                                    viewModel.logMessage("Sent basic waveform message: \(viewModel.sysEx.messageToHexString(messages[0]))")
                                    
                                    // Small delay then send second message (set variation)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        viewModel.midiManager.sendPacket(messages[1])
                                        viewModel.logMessage("Sent variation message: \(viewModel.sysEx.messageToHexString(messages[1]))")
                                        
                                        // Small delay then send third message (clear wave number)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                            viewModel.midiManager.sendPacket(messages[2])
                                            viewModel.logMessage("Sent clear wave number message: \(viewModel.sysEx.messageToHexString(messages[2]))")
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // SuperNATURAL Waveforms
                            VStack(alignment: .leading) {
                                Text("SuperNATURAL Waveforms")
                                    .font(.caption)
                                HStack {
                                    Stepper("Wave \(viewModel.selectedSuperNaturalWave)",
                                           value: $viewModel.selectedSuperNaturalWave,
                                           in: 1...450)
                                }
                                Button("Send SuperNATURAL Waveform") {
                                    let messages = viewModel.sysEx.changeSuperNaturalWaveform(to: viewModel.selectedSuperNaturalWave)
                                    
                                    // Send first message (set PCM mode)
                                    viewModel.midiManager.sendPacket(messages[0])
                                    viewModel.logMessage("Sent PCM mode message: \(viewModel.sysEx.messageToHexString(messages[0]))")
                                    
                                    // Small delay then send second message (set variation)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        viewModel.midiManager.sendPacket(messages[1])
                                        viewModel.logMessage("Sent variation message: \(viewModel.sysEx.messageToHexString(messages[1]))")
                                        
                                        // Small delay then send third message (set wave number)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                            viewModel.midiManager.sendPacket(messages[2])
                                            viewModel.logMessage("Sent wave number message: \(viewModel.sysEx.messageToHexString(messages[2]))")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Reverb Type
                    VStack(alignment: .leading) {
                        Text("Reverb Type")
                            .font(.caption)
                        HStack {
                            Slider(value: $viewModel.reverbType, in: 0...6)
                            Text("\(Int(viewModel.reverbType))")
                                .frame(width: 40)
                                .font(.caption.monospaced())
                        }
                        Button("Send Reverb Change") {
                            viewModel.changeReverbType()
                        }
                    }
                    
                    Divider()
                    
                    // HPF Cutoff
                    VStack(alignment: .leading) {
                        Text("HPF Cutoff")
                            .font(.caption)
                        HStack {
                            Slider(value: $viewModel.hpfCutoff, in: 0...127)
                            Text("\(Int(viewModel.hpfCutoff))")
                                .frame(width: 40)
                                .font(.caption.monospaced())
                        }
                        Button("Send HPF Change") {
                            viewModel.changeHPFCutoff()
                        }
                    }
                }
            }
            .padding()
            
            // Message Log
            GroupBox("Message Log") {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(viewModel.messageLog, id: \.self) { message in
                            Text(message)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                .frame(height: 200)
            }
            .padding()
        }
        .frame(width: 500)
        .padding()
    }
}
