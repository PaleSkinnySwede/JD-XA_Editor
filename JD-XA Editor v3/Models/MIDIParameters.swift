import Foundation

protocol MIDIParameter {
    var address: [UInt8] { get }
    var value: UInt8 { get }
    var partNumber: Int { get }
    var partialNumber: Int { get }
}

struct DigitalPartParameter: MIDIParameter {
    let partNumber: Int      // 1-4
    let partialNumber: Int   // 1-3
    let parameterOffset: [UInt8]
    let value: UInt8
    
    var address: [UInt8] {
        // Base address for Digital Part 1
        let baseAddress: UInt8 = 0x1A
        
        // Partial offsets: 0x20 for Partial 1, 0x21 for Partial 2, 0x22 for Partial 3
        let partialOffset: UInt8 = UInt8(0x20 + (partialNumber-1))
        
        // Combine into final address
        return [baseAddress, 0x01, partialOffset] + parameterOffset
    }
}

// Parameter address offsets
extension DigitalPartParameter {
    enum ParameterAddress {
        // OSC parameters
        static let oscWaveform: [UInt8] = [0x00]
        static let oscWaveVariation: [UInt8] = [0x01]
        static let oscPitch: [UInt8] = [0x03]
        static let oscDetune: [UInt8] = [0x04]
        static let oscPulseWidth: [UInt8] = [0x06]
        static let oscPWMDepth: [UInt8] = [0x05]
        static let oscPW: [UInt8] = [0x06]
        static let oscPitchEnvAttackTime: [UInt8] = [0x07]
        static let oscPitchEnvDecayTime: [UInt8] = [0x08]
        static let oscPitchEnvDepth: [UInt8] = [0x09]
        static let oscWaveGain: [UInt8] = [0x34]
        static let oscWaveNumber: [UInt8] = [0x35]
        static let oscSuperSawDetune: [UInt8] = [0x3A]

        // Filter parameters
        static let fltMode: [UInt8] = [0x0A]
        static let fltSlope: [UInt8] = [0x0B]
        static let fltCutoff: [UInt8] = [0x0C]
        static let fltCutoffKeyFollow: [UInt8] = [0x0D]
        static let fltEnvVelSens: [UInt8] = [0x0E]
        static let fltResonance: [UInt8] = [0x0F]
        static let fltEnvAttackTime: [UInt8] = [0x10]
        static let fltEnvDecayTIme: [UInt8] = [0x11]
        static let fltEnvSustainLevel: [UInt8] = [0x12]
        static let fltEnvReleaseTime: [UInt8] = [0x13]
        static let fltEnvDepth: [UInt8] = [0x14]
        static let fltCutoffATSens: [UInt8] = [0x30]
        static let fltLevelATSens: [UInt8] = [0x31]
        static let fltHPCutoff: [UInt8] = [0x39]

        // AMP parameters
        static let ampLevel: [UInt8] = [0x15]
        static let ampVelSens: [UInt8] = [0x16]
        static let ampAttackTime: [UInt8] = [0x17]
        static let ampDecayTime: [UInt8] = [0x18]
        static let ampSustainLevel: [UInt8] = [0x19]
        static let ampReleaseTime: [UInt8] = [0x1A]
        static let ampPan: [UInt8] = [0x1B]
        static let ampKeyFollow: [UInt8] = [0x3C]
        
        // LFO parameters
        static let lfoShape: [UInt8] = [0x1C]
        static let lfoRate: [UInt8] = [0x1D]
        static let lfoSync: [UInt8] = [0x1E]
        static let lfoSyncNote: [UInt8] = [0x1F]
        static let lfoFadeTime: [UInt8] = [0x20]
        static let lfoKeyTrigger: [UInt8] = [0x21]
        static let lfoPitchDepth: [UInt8] = [0x22]
        static let lfoFilterDepth: [UInt8] = [0x23]
        static let lfoAmpDepth: [UInt8] = [0x24]
        static let lfoPanDepth: [UInt8] = [0x25]
        
        // MOD-LFO parameters
        static let modLfoShape: [UInt8] = [0x26]
        static let modLfoRate: [UInt8] = [0x27]
        static let modLfoSync: [UInt8] = [0x28]
        static let modLfoSyncNote: [UInt8] = [0x29]
        static let modLfoPitchDepth: [UInt8] = [0x2C]
        static let modLfoFilterDepth: [UInt8] = [0x2D]
        static let modLfoAmpDepth: [UInt8] = [0x2E]
        static let modLfoPanDepth: [UInt8] = [0x2F]
        static let modLfoRateCtrl: [UInt8] = [0x3B]
    }
}
