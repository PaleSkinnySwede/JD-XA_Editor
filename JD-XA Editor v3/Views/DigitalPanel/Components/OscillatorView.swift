import SwiftUI

struct OscillatorView: View {
    @ObservedObject var viewModel: OscillatorViewModel

    var body: some View {
        SectionCard("Oscillator", systemImage: "waveform.path", tint: SectionTint.osc, accessory: {
            VariationPicker(
                selectedWaveform: viewModel.selectedWaveform,
                selectedVariation: viewModel.selectedVariation,
                isPCM: viewModel.pcmWaveNumber != nil
            ) { variation in
                viewModel.updateWaveform(waveform: viewModel.selectedWaveform, variation: variation)
            }
        }) {
            VStack(alignment: .leading, spacing: 18) {
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

                HStack(alignment: .top, spacing: 20) {
                    ControlGroupBox("Tuning") {
                        HStack(spacing: 8) {
                            DialKnob(title: "Pitch", value: $viewModel.pitch, range: -24...24)
                            DialKnob(title: "Detune", value: $viewModel.detune, range: -50...50)
                        }
                    }

                    ControlDivider()

                    ControlGroupBox("Shape") {
                        HStack(alignment: .top, spacing: 4) {
                            VerticalSlider(title: "PWM", value: $viewModel.pwmDepth, range: 0...127, defaultValue: 0)
                            VerticalSlider(title: "PW", value: $viewModel.pulseWidth, range: 0...127, defaultValue: 64)
                            VerticalSlider(title: "PW Shift", value: $viewModel.pwShift, range: 0...127, defaultValue: 0)
                            VerticalSlider(title: "S-Saw", value: $viewModel.superSawDetune, range: 0...127, defaultValue: 64)
                                .disabled(!viewModel.isSuperSaw)
                                .opacity(viewModel.isSuperSaw ? 1 : 0.35)
                                .help("Super Saw detune. Available when SUPER-SAW is selected.")
                            VerticalSlider(
                                title: "Gain",
                                value: $viewModel.pcmGain,
                                range: -6...12,
                                defaultValue: 0,
                                values: [-6, 0, 6, 12]
                            )
                            .disabled(viewModel.pcmWaveNumber == nil)
                            .opacity(viewModel.pcmWaveNumber == nil ? 0.35 : 1)
                            .help("PCM wave gain. Available when a PCM wave is selected.")
                        }
                    }

                    ControlDivider()

                    ControlGroupBox("Pitch Envelope") {
                        HStack(alignment: .top, spacing: 4) {
                            DialKnob(title: "Depth", value: $viewModel.pitchEnvDepth, range: -63...63, defaultValue: 0)
                            VerticalSlider(title: "Attack", value: $viewModel.pitchEnvAttack, range: 0...127, defaultValue: 0)
                            VerticalSlider(title: "Decay", value: $viewModel.pitchEnvDecay, range: 0...127, defaultValue: 127)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

class OscillatorViewModel: ObservableObject {
    private let midiService: MIDIService
    private let partNumber: Int
    private let partialNumber: Int
    
    // Waveform state. Changes are sent only through `updateWaveform` and
    // `updatePCMWaveform`, so each user action sends exactly one set of messages.
    // A non-nil `pcmWaveNumber` means the oscillator is in PCM mode.
    @Published var selectedWaveform: DOscWaveform = .saw
    @Published var selectedVariation: WaveformVariation = .a
    @Published var pcmWaveNumber: Int?

    var isSuperSaw: Bool { selectedWaveform == .superSaw && pcmWaveNumber == nil }

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

    /// Selects a basic waveform (leaving PCM mode if it was on)
    func updateWaveform(waveform: DOscWaveform, variation: WaveformVariation) {
        selectedWaveform = waveform
        selectedVariation = variation
        pcmWaveNumber = nil

        midiService.setOscillatorWaveform(
            partNumber: partNumber,
            partialNumber: partialNumber,
            waveform: waveform,
            variation: variation
        )
    }

    /// Selects a PCM wave. `nil` leaves PCM mode and goes back to the basic waveform.
    func updatePCMWaveform(number: Int?) {
        guard let number else {
            updateWaveform(waveform: selectedWaveform, variation: selectedVariation)
            return
        }
        pcmWaveNumber = number

        midiService.setOscillatorPCMWave(
            partNumber: partNumber,
            partialNumber: partialNumber,
            waveNumber: number
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
        OscillatorView(viewModel: OscillatorViewModel(
            partNumber: 1, partialNumber: 1,
            midiService: MIDIService(midiManager: MIDIManager())
        ))
        .padding()
        .background(ThemeColors.background)
    }
}
