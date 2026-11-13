import CoreMIDI

class JDXASysEx {
    // MARK: - Constants
    private enum Constants {
        static let manufacturerId: UInt8 = 0x41  // Roland
        static let deviceId: UInt8 = 0x10       // Device ID can be 10H-1FH, 7FH
        static let modelId: [UInt8] = [0x00, 0x00, 0x00, 0x0F]  // JD-XA
    }
    
    // MARK: - Command Types
    private enum Command: UInt8 {
        case dt1 = 0x12    // Data Set 1
        case rq1 = 0x11    // Data Request 1
    }
    
    // MARK: - SysEx Message Building
    /// Builds a complete SysEx message with header, data, checksum, and terminator
    private func buildSysExMessage(command: Command, data: [UInt8]) -> [UInt8] {
        var message: [UInt8] = [
            0xF0,                   // Start of SysEx
            Constants.manufacturerId,// Roland ID
            Constants.deviceId      // Device ID
        ]
        
        // Add model ID
        message.append(contentsOf: Constants.modelId)
        
        // Add command
        message.append(command.rawValue)
        
        // Add data
        message.append(contentsOf: data)
        
        // Calculate and add checksum
        let checksum = calculateChecksum(data)
        message.append(checksum)
        
        // Add end of SysEx
        message.append(0xF7)
        
        return message
    }
    
    /// Calculates checksum for Roland format: 128 - (sum of address and data % 128)
    private func calculateChecksum(_ data: [UInt8]) -> UInt8 {
        let sum = data.reduce(0, +)
        return UInt8((128 - (sum % 128)) % 128)
    }
    
    // MARK: - Common Messages
    /// Creates a Device Inquiry request message
    func createDeviceInquiry() -> [UInt8] {
        return [
            0xF0,   // Start of SysEx
            0x7E,   // Universal Non-realtime
            0x7F,   // Device ID (broadcast)
            0x06,   // Sub ID#1 (General Information)
            0x01,   // Sub ID#2 (Identity Request)
            0xF7    // End of SysEx
        ]
    }
    
    /// Creates a DT1 message to change a parameter
    func createParameterChange(address: [UInt8], value: UInt8) -> [UInt8] {
        let data = address + [value]
        return buildSysExMessage(command: .dt1, data: data)
    }
    
    /// Creates an RQ1 message to request parameter data
    func createParameterRequest(address: [UInt8], size: [UInt8]) -> [UInt8] {
        let data = address + size
        return buildSysExMessage(command: .rq1, data: data)
    }
    
    // MARK: - Common Parameter Addresses
    enum ParameterAddress {
        /// Digital OSC waveform for Digital Part 1, Partial 1
        static let digitalOsc1Waveform: [UInt8] = [0x1A, 0x01, 0x20, 0x00]
        
        /// Program Reverb Type
        static let programReverbType: [UInt8] = [0x18, 0x00, 0x02, 0x01]
        
        /// Digital Part 1, Digital Partial 1, HPF Cutoff
        static let digitalPart1HpfCutoff: [UInt8] = [0x1A, 0x01, 0x20, 0x39]
    }
    
    // MARK: - Example Parameter Changes
    /// Changes Digital OSC 1 basic waveform (SAW-A, SQR-A, etc)
    func changeDigitalOscWaveform(to waveform: DOscWaveform, variation: WaveformVariation) -> [[UInt8]] {
        // First message: Set basic waveform
        let setWaveTypeAddress: [UInt8] = [0x1A, 0x01, 0x20, 0x00]
        let setWaveMessage = createParameterChange(
            address: setWaveTypeAddress,
            value: waveform.rawValue
        )
        
        // Second message: Set variation
        let setVariationAddress: [UInt8] = [0x1A, 0x01, 0x20, 0x01]
        let setVariationMessage = createParameterChange(
            address: setVariationAddress,
            value: variation.rawValue
        )
        
        // Third message: Clear SuperNATURAL wave number
        let setWaveNumberAddress: [UInt8] = [0x1A, 0x01, 0x20, 0x35]
        let clearNibbles: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        let data = setWaveNumberAddress + clearNibbles
        let clearWaveNumberMessage = buildSysExMessage(command: .dt1, data: data)
        
        return [setWaveMessage, setVariationMessage, clearWaveNumberMessage]
    }
    
    /// Changes Digital OSC 1 to a SuperNATURAL waveform (1-450)
    // Add this new helper method first
    func setOscWaveType(to type: Int) -> [UInt8] {
        let address: [UInt8] = [0x1A, 0x00, 0x20, 0x00]  // Digital Part 1, OSC Wave
        return createParameterChange(address: address, value: UInt8(type))
    }

    // Then modify this method to return single message
    func changeSuperNaturalWaveform(to waveNumber: Int) -> [[UInt8]] {
        // First message: Set OSC Wave to PCM
        let setWaveTypeAddress: [UInt8] = [0x1A, 0x01, 0x20, 0x00]
        let setPCMMessage = createParameterChange(address: setWaveTypeAddress, value: 7)
        
        // Second message: Set variation to A
        let setVariationAddress: [UInt8] = [0x1A, 0x01, 0x20, 0x01]
        let setVariationMessage = createParameterChange(address: setVariationAddress, value: 0)
        
        // Third message: Set Wave Number
        let value = min(max(1, waveNumber), 450)
        
        let setWaveNumberAddress: [UInt8] = [0x1A, 0x01, 0x20, 0x35]
        
        // Convert value to 4 nibbles (as per MIDI implementation doc format)
        let nibbles: [UInt8] = [
            0x00,   // Always 00
            0x00,   // Always 00
            UInt8((value >> 4) & 0x0F),   // Upper nibble
            UInt8(value & 0x0F)           // Lower nibble
        ]
        
        let data = setWaveNumberAddress + nibbles
        let setWaveNumberMessage = buildSysExMessage(command: .dt1, data: data)
        
        return [setPCMMessage, setVariationMessage, setWaveNumberMessage]
    }
    
    /// Changes Program Reverb Type
    func changeProgramReverbType(to type: UInt8) -> [UInt8] {
        return createParameterChange(
            address: ParameterAddress.programReverbType,
            value: type
        )
    }
    
    /// Changes HPF Cutoff for Digital Part 1
    func changeDigitalHpfCutoff(to value: UInt8) -> [UInt8] {
        return createParameterChange(
            address: ParameterAddress.digitalPart1HpfCutoff,
            value: value
        )
    }
}

// MARK: - SysEx Message Handling Extension
extension JDXASysEx {
    /// Process incoming SysEx messages
    func processSysExMessage(_ message: [UInt8]) -> String {
        // First validate message format
        guard message.first == 0xF0,
              message.last == 0xF7 else {
            return "Invalid SysEx message format"
        }
        
        // Device Inquiry Response
        if message.count >= 5 &&
           message[1] == 0x7E &&
           message[3] == 0x06 &&
           message[4] == 0x02 {
            return processDeviceInquiryResponse(message)
        }
        
        // DT1 Response
        if message.count >= 7 &&
           message[1] == Constants.manufacturerId &&
           message[6] == Constants.modelId[3] &&
           message[7] == Command.dt1.rawValue {
            return processDT1Response(message)
        }
        
        return "Unknown SysEx message type"
    }
    
    private func processDeviceInquiryResponse(_ message: [UInt8]) -> String {
        guard message.count == 15 else {
            return "Invalid Device Inquiry Response length"
        }
        
        let softwareVersion = String(format: "v%d.%d.%d.%d",
                                   message[9], message[10],
                                   message[11], message[12])
        
        return "JD-XA Identity Response - Software Version: \(softwareVersion)"
    }
    
    private func processDT1Response(_ message: [UInt8]) -> String {
        guard message.count >= 11 else {
            return "Invalid DT1 Response length"
        }
        
        let address = Array(message[8...11])
        let addressStr = address.map { String(format: "%02X", $0) }.joined(separator: " ")
        
        // Get data bytes (excluding checksum and F7)
        let data = Array(message[12..<(message.count-2)])
        let dataStr = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        
        return "Parameter Change - Address: \(addressStr), Data: \(dataStr)"
    }
}

extension JDXASysEx {
    func buildPCMMessage(address: [UInt8], data: [UInt8]) -> [UInt8] {
        var message: [UInt8] = [
            0xF0,                     // Start of SysEx
            Constants.manufacturerId, // Roland ID
            Constants.deviceId,       // Device ID
            0x00, 0x00, 0x00, 0x0F,   // Model ID
            0x12                      // Command (DT1)
        ]
        
        // Add address
        message.append(contentsOf: address)
        
        // Add data bytes
        message.append(contentsOf: data)
        
        // Calculate checksum
        let checksum = calculateChecksum(address + data)
        message.append(checksum)
        
        // End of SysEx
        message.append(0xF7)
        
        return message
    }
}

// MARK: - Debug Helper Extension
extension JDXASysEx {
    /// Returns a hex string representation of a message for debugging
    func messageToHexString(_ message: [UInt8]) -> String {
        return message.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
    
    /// Validates a complete message including checksum
    func validateMessage(_ message: [UInt8]) -> Bool {
        guard message.count >= 4,
              message.first == 0xF0,
              message.last == 0xF7 else {
            return false
        }
        
        // For messages with checksum (DT1, RQ1)
        if message[1] == Constants.manufacturerId {
            let data = Array(message.dropFirst(8).dropLast(2))
            let providedChecksum = message[message.count - 2]
            let calculatedChecksum = calculateChecksum(data)
            return providedChecksum == calculatedChecksum
        }
        
        return true
    }
}
