public enum LFOShape: String, CaseIterable {
    case tri = "TRI"
    case sin = "SIN"
    case saw = "SAW"
    case sqr = "SQR"
    case sAndH = "S&H"
    case rnd = "RND"
    
    var name: String { rawValue }
}

public struct TempoSyncValue: Equatable {
    let id: Int
    let label: String
    
    static let values: [TempoSyncValue] = [
        TempoSyncValue(id: 0, label: "16/1"),
        TempoSyncValue(id: 1, label: "12/1"),
        TempoSyncValue(id: 2, label: "8/1"),
        TempoSyncValue(id: 3, label: "4/1"),
        TempoSyncValue(id: 4, label: "2/1"),
        TempoSyncValue(id: 5, label: "1/1"),
        TempoSyncValue(id: 6, label: "3/4"),
        TempoSyncValue(id: 7, label: "2/3"),
        TempoSyncValue(id: 8, label: "1/2"),
        TempoSyncValue(id: 9, label: "3/8"),
        TempoSyncValue(id: 10, label: "1/3"),
        TempoSyncValue(id: 11, label: "1/4"),
        TempoSyncValue(id: 12, label: "3/16"),
        TempoSyncValue(id: 13, label: "1/6"),
        TempoSyncValue(id: 14, label: "1/8"),
        TempoSyncValue(id: 15, label: "3/32"),
        TempoSyncValue(id: 16, label: "1/12"),
        TempoSyncValue(id: 17, label: "1/16"),
        TempoSyncValue(id: 18, label: "1/24"),
        TempoSyncValue(id: 19, label: "1/32")
    ]
    
    static let defaultValue = values.first { $0.label == "1/4" }!
}
