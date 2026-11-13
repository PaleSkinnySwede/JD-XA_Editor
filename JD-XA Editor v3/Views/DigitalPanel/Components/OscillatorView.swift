import SwiftUI

struct OscillatorView: View {
    let partNumber: Int
    let partialNumber: Int
    @StateObject private var viewModel: OscillatorViewModel
    
    init(partNumber: Int, partialNumber: Int, midiService: MIDIService) {
        self.partNumber = partNumber
        self.partialNumber = partialNumber
        _viewModel = StateObject(wrappedValue: OscillatorViewModel(
            partNumber: partNumber,
            partialNumber: partialNumber,
            midiService: midiService
        ))
    }
    
    var body: some View {
        VStack(spacing: ThemeMetrics.spacing) {
            // Title
            Text("Oscillator Controls")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            // Content area with dark background
            VStack(spacing: ThemeMetrics.spacing * 2) {
                // Waveform Selection
                VStack(alignment: .leading, spacing: ThemeMetrics.spacing) {
                    Text("Waveform")
                        .foregroundColor(ThemeColors.secondaryText)
                        .font(.subheadline)
                    
                    WaveformPicker(
                        selectedWaveform: $viewModel.selectedWaveform,
                        selectedVariation: $viewModel.selectedVariation,
                        pcmWaveNumber: $viewModel.pcmWaveNumber,
                        onWaveformUpdate: { waveform, variation in
                            viewModel.updateWaveform(waveform: waveform, variation: variation)
                        },
                        onPCMUpdate: { number in
                            viewModel.updatePCMWaveform(number: number)
                        }
                    )
                }
                
                // Main Controls Section
                HStack(spacing: ThemeMetrics.spacing * 3) {
                    // Knob Controls
                    HStack(spacing: ThemeMetrics.spacing * 2) {
                        DialKnob(
                            title: "Pitch",
                            value: $viewModel.pitch,
                            range: -24...24
                        )
                        
                        DialKnob(
                            title: "Detune",
                            value: $viewModel.detune,
                            range: -50...50
                        )
                    }
                    
                    // Basic Vertical Sliders
                    HStack(spacing: ThemeMetrics.spacing) {
                        VerticalSlider(
                            title: "PWM",
                            value: $viewModel.pwmDepth,
                            range: 0...127,
                            defaultValue: 0
                        )
                        
                        VerticalSlider(
                            title: "PW",
                            value: $viewModel.pulseWidth,
                            range: 0...127,
                            defaultValue: 64
                        )
                        
                        VerticalSlider(
                            title: "PW Shift",
                            value: $viewModel.pwShift,
                            range: 0...127,
                            defaultValue: 0
                        )
                        
                        // Always show S-Saw and Gain sliders
                        VerticalSlider(
                            title: "S-Saw",
                            value: $viewModel.superSawDetune,
                            range: 0...127,
                            defaultValue: 64
                        )
                        .disabled(viewModel.selectedWaveform != .superSaw)
                        .opacity(viewModel.selectedWaveform != .superSaw ? 0.5 : 1)
                        
                        VerticalSlider(
                            title: "Gain",
                            value: $viewModel.pcmGain,
                            range: -6...12,
                            defaultValue: 0,
                            values: [-6, 0, 6, 12]
                        )
                        .disabled(viewModel.pcmWaveNumber == nil)
                        .opacity(viewModel.pcmWaveNumber == nil ? 0.5 : 1)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(ThemeColors.secondaryBackground)
                        .frame(width: 1, height: 150)
                        .padding(.horizontal, ThemeMetrics.spacing)
                    
                    // Pitch Envelope Section
                    VStack(alignment: .center, spacing: ThemeMetrics.spacing) {
                        Text("PITCH ENV")
                            .font(.caption)
                            .foregroundColor(ThemeColors.secondaryText)
                        
                        HStack(spacing: ThemeMetrics.spacing * 2) {
                            // Depth Knob
                            DialKnob(
                                title: "Depth",
                                value: $viewModel.pitchEnvDepth,
                                range: -63...63,
                                defaultValue: 0
                            )
                            
                            // Attack and Decay Sliders
                            HStack(spacing: ThemeMetrics.spacing) {
                                VerticalSlider(
                                    title: "Attack",
                                    value: $viewModel.pitchEnvAttack,
                                    range: 0...127,
                                    defaultValue: 0
                                )
                                
                                VerticalSlider(
                                    title: "Decay",
                                    value: $viewModel.pitchEnvDecay,
                                    range: 0...127,
                                    defaultValue: 127
                                )
                            }
                        }
                    }
                }
            }
            .padding()
            .background(ThemeColors.secondaryBackground)
            .cornerRadius(ThemeMetrics.cornerRadius)
        }
        .padding()
        .background(ThemeColors.background)
        .onChange(of: viewModel.selectedWaveform) { _ in
            viewModel.sendWaveformChange()
        }
        .onChange(of: viewModel.selectedVariation) { _ in
            viewModel.sendWaveformChange()
        }
        .onChange(of: viewModel.pcmWaveNumber) { _ in
            viewModel.sendWaveformChange()
        }
    }
}

class OscillatorViewModel: ObservableObject {
    private let midiService: MIDIService
    private let partNumber: Int
    private let partialNumber: Int
    
    @Published var selectedWaveform: DOscWaveform = .saw
    @Published var selectedVariation: WaveformVariation = .a
    @Published var pcmWaveNumber: Int?

    // Parameters with MIDI update handlers
    @Published var pitch: Double = 0 {
        didSet { sendPitchChange() }
    }
    
    @Published var detune: Double = 0 {
        didSet { sendDetuneChange() }
    }
    
    @Published var pwmDepth: Double = 0 {
        didSet { sendPWMDepthChange() }
    }
    
    @Published var pulseWidth: Double = 64 {
        didSet { sendPulseWidthChange() }
    }
    
    @Published var pwShift: Double = 0
    @Published var superSawDetune: Double = 64
    @Published var pcmGain: Double = 0
    
    // Pitch Envelope parameters
    @Published var pitchEnvDepth: Double = 0
    @Published var pitchEnvAttack: Double = 0
    @Published var pitchEnvDecay: Double = 127
    
    init(partNumber: Int, partialNumber: Int, midiService: MIDIService) {
        self.partNumber = partNumber
        self.partialNumber = partialNumber
        self.midiService = midiService
    }

    func updateWaveform(waveform: DOscWaveform, variation: WaveformVariation) {
        selectedWaveform = waveform
        selectedVariation = variation
        pcmWaveNumber = nil  // Clear PCM when selecting a basic waveform
        
        // Send MIDI update once
        midiService.setOscillatorWaveform(
            partNumber: partNumber,
            partialNumber: partialNumber,
            waveform: selectedWaveform,
            variation: selectedVariation
        )
    }
    
    func updatePCMWaveform(number: Int?) {
        pcmWaveNumber = number
        if number != nil {
            selectedWaveform = .superSaw  // or whatever your PCM mode value is
            selectedVariation = .a
        }
        
        // Send MIDI update once
        midiService.setOscillatorWaveform(
            partNumber: partNumber,
            partialNumber: partialNumber,
            waveform: selectedWaveform,
            variation: selectedVariation
        )
    }
    
    // Changed from private to fileprivate
    fileprivate func sendWaveformChange() {
        midiService.setOscillatorWaveform(
            partNumber: partNumber,
            partialNumber: partialNumber,
            waveform: selectedWaveform,
            variation: selectedVariation
        )
    }
    
    fileprivate func sendPitchChange() {
        let param = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscPitch,
            value: UInt8(pitch + 64)  // Convert from -24...+24 to 40...88
        )
        midiService.sendParameterChange(param)
    }
    
    fileprivate func sendDetuneChange() {
        let param = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscDetune,
            value: UInt8(detune + 64)  // Convert from -50...+50 to 14...114
        )
        midiService.sendParameterChange(param)
    }
    
    fileprivate func sendPWMDepthChange() {
        let param = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscPWMDepth,
            value: UInt8(pwmDepth)
        )
        midiService.sendParameterChange(param)
    }
    
    fileprivate func sendPulseWidthChange() {
        let param = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscPulseWidth,
            value: UInt8(pulseWidth)
        )
        midiService.sendParameterChange(param)
    }
}

struct OscillatorView_Previews: PreviewProvider {
    static var previews: some View {
        OscillatorView(partNumber: 1, partialNumber: 1, midiService: MIDIService(midiManager: MIDIManager()))
            .background(ThemeColors.background)
    }
}
