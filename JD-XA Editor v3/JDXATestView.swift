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
    
    func sendBasicWaveform() {
        let messages = sysEx.changeDigitalOscWaveform(
            to: selectedBasicWaveform,
            variation: selectedWaveformVariation
        )
        sendSpaced(messages, labels: ["basic waveform", "variation", "clear wave number"])
    }

    func sendSuperNaturalWaveform() {
        let messages = sysEx.changeSuperNaturalWaveform(to: selectedSuperNaturalWave)
        sendSpaced(messages, labels: ["PCM mode", "variation", "wave number"])
    }

    /// Sends messages 50 ms apart so the synth can keep up.
    private func sendSpaced(_ messages: [[UInt8]], labels: [String], index: Int = 0) {
        guard index < messages.count else { return }
        midiManager.sendPacket(messages[index])
        let label = index < labels.count ? labels[index] : "message \(index + 1)"
        logMessage("Sent \(label): \(sysEx.messageToHexString(messages[index]))")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.sendSpaced(messages, labels: labels, index: index + 1)
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    func clearLog() {
        messageLog.removeAll()
    }

    func logMessage(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = Self.timeFormatter.string(from: Date())
            let logEntry = "\(timestamp)  \(message)"
            self.messageLog.insert(logEntry, at: 0)
            if self.messageLog.count > 100 {
                self.messageLog = Array(self.messageLog.prefix(100))
            }
        }
    }
}

// MARK: - View

/// Sends single test messages and shows a log of what went out.
struct JDXATestView: View {
    @ObservedObject var viewModel: JDXATestViewModel

    private var isConnected: Bool { viewModel.selectedDeviceID != nil }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ScrollView {
                VStack(spacing: 12) {
                    if !isConnected {
                        Label("No MIDI output selected. Choose one in the sidebar to send messages.",
                              systemImage: "cable.connector.slash")
                            .font(.callout)
                            .foregroundColor(ThemeColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(ThemeColors.disconnected.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }

                    SectionCard("Oscillator Waveform", systemImage: "waveform.path", tint: SectionTint.osc) {
                        VStack(alignment: .leading, spacing: 14) {
                            ControlGroupBox("Basic waveform") {
                                HStack {
                                    Picker("Waveform", selection: $viewModel.selectedBasicWaveform) {
                                        ForEach(DOscWaveform.allCases, id: \.self) { waveform in
                                            Text(waveform.name).tag(waveform)
                                        }
                                    }
                                    .labelsHidden()
                                    Picker("Variation", selection: $viewModel.selectedWaveformVariation) {
                                        ForEach(WaveformVariation.allCases, id: \.self) { variation in
                                            Text(variation.name).tag(variation)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 70)
                                    Spacer()
                                    Button("Send", action: viewModel.sendBasicWaveform)
                                }
                            }

                            Divider()

                            ControlGroupBox("SuperNATURAL (PCM) wave") {
                                HStack {
                                    Stepper("Wave \(viewModel.selectedSuperNaturalWave)",
                                            value: $viewModel.selectedSuperNaturalWave,
                                            in: MIDIService.pcmWaveRange)
                                        .monospacedDigit()
                                    if let wave = PCMWaveDatabase.findWave(id: viewModel.selectedSuperNaturalWave) {
                                        Text(wave.name)
                                            .foregroundColor(ThemeColors.secondaryText)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Button("Send", action: viewModel.sendSuperNaturalWaveform)
                                }
                            }
                        }
                    }

                    SectionCard("Program Reverb", systemImage: "dot.radiowaves.right", tint: SectionTint.lfo) {
                        TestSliderRow(value: $viewModel.reverbType, range: 0...6, label: "Type",
                                      send: viewModel.changeReverbType)
                    }

                    SectionCard("Digital HPF", systemImage: "line.diagonal", tint: SectionTint.filter) {
                        TestSliderRow(value: $viewModel.hpfCutoff, range: 0...127, label: "Cutoff",
                                      send: viewModel.changeHPFCutoff)
                    }
                }
                .padding(20)
            }
            .frame(minWidth: 380, idealWidth: 460, maxWidth: 520)

            MessageLogView(viewModel: viewModel)
                .padding([.vertical, .trailing], 20)
        }
        .background(ThemeColors.background)
        .navigationTitle("MIDI Test Panel")
        .navigationSubtitle(isConnected ? "Sending to the selected output" : "Offline")
    }
}

private struct TestSliderRow: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let label: String
    let send: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .foregroundColor(ThemeColors.secondaryText)
                .frame(width: 50, alignment: .leading)
            Slider(value: $value, in: range, step: 1)
            Text("\(Int(value))")
                .font(.system(.body, design: .monospaced))
                .frame(width: 36, alignment: .trailing)
            Button("Send", action: send)
        }
    }
}

private struct MessageLogView: View {
    @ObservedObject var viewModel: JDXATestViewModel

    var body: some View {
        SectionCard("Message Log", systemImage: "list.bullet.rectangle", tint: ThemeColors.accent, accessory: {
            Button("Clear", action: viewModel.clearLog)
                .controlSize(.small)
                .disabled(viewModel.messageLog.isEmpty)
        }) {
            if viewModel.messageLog.isEmpty {
                Text("Messages you send appear here.")
                    .foregroundColor(ThemeColors.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(viewModel.messageLog.enumerated()), id: \.offset) { _, message in
                            Text(message)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(ThemeColors.text.opacity(0.85))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}
