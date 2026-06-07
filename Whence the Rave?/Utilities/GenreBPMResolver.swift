import Foundation

struct GenreBPMResolver {
    private static let defaultBPM = 120
    private static let minBPM = 90
    private static let maxBPM = 180

    /// Longer keys first so "tech house" matches before "house".
    private static let bpmTable: [(key: String, bpm: Int)] = [
        ("drum and bass", 174),
        ("drum & bass", 174),
        ("drum n bass", 174),
        ("dnb", 174),
        ("tech house", 125),
        ("deep house", 122),
        ("progressive house", 128),
        ("hard house", 150),
        ("acid house", 128),
        ("minimal techno", 128),
        ("hard techno", 145),
        ("melodic techno", 124),
        ("progressive trance", 138),
        ("hard trance", 145),
        ("breakbeat", 130),
        ("hardstyle", 150),
        ("hardcore", 170),
        ("jungle", 160),
        ("garage", 130),
        ("uk garage", 130),
        ("dubstep", 140),
        ("ambient", 90),
        ("downtempo", 95),
        ("electro", 128),
        ("disco", 118),
        ("funk", 115),
        ("soul", 110),
        ("minimal", 125),
        ("industrial", 130),
        ("ebm", 130),
        ("trance", 138),
        ("techno", 130),
        ("house", 124),
        ("bass", 140),
    ]

    static func bpm(forGenreName name: String) -> Int {
        let normalized = normalize(name)
        guard !normalized.isEmpty else { return defaultBPM }

        for entry in bpmTable {
            if normalized == entry.key {
                return clamp(entry.bpm)
            }
        }

        for entry in bpmTable {
            if normalized.contains(entry.key) {
                return clamp(entry.bpm)
            }
        }

        return defaultBPM
    }

    static func bpms(for genres: [RAGenre]) -> [(genre: RAGenre, bpm: Int)] {
        genres.map { ($0, bpm(forGenreName: $0.name)) }
    }

    private static func normalize(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func clamp(_ bpm: Int) -> Int {
        min(max(bpm, minBPM), maxBPM)
    }
}
