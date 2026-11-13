import Foundation

class MIDIService {
    private let sysEx: JDXASysEx
    private let midiManager: MIDIManager
    
    init(midiManager: MIDIManager) {
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
        
        // Special handling for PCM wave number clear - it needs 4 data bytes
        let clearPCMAddress: [UInt8] = [0x1A, 0x01, 0x20, 0x35]
        let clearPCMData: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        let clearPCMMessage = sysEx.buildPCMMessage(address: clearPCMAddress, data: clearPCMData)
        
        // Send all parameters in sequence
        sendParameterChange(waveformParam)
        sendParameterChange(variationParam)
        midiManager.sendPacket(clearPCMMessage)
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
