import Foundation

/// Anything that can send a raw MIDI message. `MIDIManager` is the real one;
/// tests use a recorder.
protocol MIDISending: AnyObject {
    func sendPacket(_ data: [UInt8])
}

extension MIDIManager: MIDISending {}

class MIDIService {
    private let sysEx: JDXASysEx
    private let midiManager: MIDISending

    /// OSC Wave value for PCM (SuperNATURAL) waves. Not a `DOscWaveform` case
    /// because the picker shows every case as a basic-waveform button.
    static let pcmWaveformValue: UInt8 = 7

    /// Valid SuperNATURAL PCM wave numbers
    static let pcmWaveRange = 1...450
    
    init(midiManager: MIDISending) {
        self.midiManager = midiManager
        self.sysEx = JDXASysEx()
    }
    
    func sendParameterChange(_ parameter: MIDIParameter) {
        // Create Data Set 1 (DT1) message using parameter address and value
        let message = sysEx.createParameterChange(
            address: parameter.address,
            value: parameter.value
        )
        
        // Send via MIDI manager
        midiManager.sendPacket(message)
    }
    
    // Helper method for sending multiple parameter changes
    func sendParameterChanges(_ parameters: [MIDIParameter]) {
        parameters.forEach { sendParameterChange($0) }
    }
}

// Convenience methods for common parameter changes
extension MIDIService {
    func setOscillatorWaveform(
        partNumber: Int,
        partialNumber: Int,
        waveform: DOscWaveform,
        variation: WaveformVariation
    ) {
        // Send waveform type
        let waveformParam = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscWaveform,
            value: waveform.rawValue
        )
        
        // Send variation
        let variationParam = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscWaveVariation,
            value: variation.rawValue
        )
        
        // Send all parameters in sequence, then clear the PCM wave number
        sendParameterChange(waveformParam)
        sendParameterChange(variationParam)
        sendWaveNumber(partNumber: partNumber, partialNumber: partialNumber, number: 0)
    }

    /// Switches the oscillator to a PCM (SuperNATURAL) wave: OSC Wave = PCM,
    /// variation A, then the wave number (clamped to 1...450).
    func setOscillatorPCMWave(
        partNumber: Int,
        partialNumber: Int,
        waveNumber: Int
    ) {
        let waveformParam = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscWaveform,
            value: MIDIService.pcmWaveformValue
        )
        let variationParam = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscWaveVariation,
            value: WaveformVariation.a.rawValue
        )
        let number = min(max(waveNumber, MIDIService.pcmWaveRange.lowerBound),
                         MIDIService.pcmWaveRange.upperBound)

        sendParameterChange(waveformParam)
        sendParameterChange(variationParam)
        sendWaveNumber(partNumber: partNumber, partialNumber: partialNumber, number: number)
    }

    /// The wave number spans 4 nibble bytes, so it can't go through `sendParameterChange`.
    private func sendWaveNumber(partNumber: Int, partialNumber: Int, number: Int) {
        let address = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscWaveNumber,
            value: 0
        ).address
        let message = sysEx.createParameterChange(
            address: address,
            data: JDXASysEx.encodeNibbles(number)
        )
        midiManager.sendPacket(message)
    }
    
    func setOscillatorPitch(
        partNumber: Int,
        partialNumber: Int,
        pitch: Double
    ) {
        let param = DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: DigitalPartParameter.ParameterAddress.oscPitch,
            value: UInt8(pitch + 64) // Convert from -24...+24 to 40...88
        )
        sendParameterChange(param)
    }
    
    // Add more convenience methods for other parameters...
}
