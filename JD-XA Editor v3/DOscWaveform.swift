public enum DOscWaveform: UInt8, CaseIterable {
    case saw = 0
    case square = 1
    case pwSquare = 2
    case triangle = 3
    case sine = 4
    case noise = 5
    case superSaw = 6
///    case pcm = 7
    
    var name: String {
        switch self {
        case .saw: return "SAW"
        case .square: return "SQR"
        case .pwSquare: return "PW-SQR"
        case .triangle: return "TRI"
        case .sine: return "SINE"
        case .noise: return "NOISE"
        case .superSaw: return "SUPER-SAW"
///        case .pcm: return "PCM"
        }
    }
}

public enum WaveformVariation: UInt8, CaseIterable {
    case a = 0
    case b = 1
    case c = 2

    var name: String {
        switch self {
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        }
    }
}
