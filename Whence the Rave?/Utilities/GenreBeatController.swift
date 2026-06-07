import Combine
import Foundation

final class GenreBeatController: ObservableObject {
    @Published private(set) var activeGenreId: String?
    @Published private(set) var beatPulse = false

    private var genreSlots: [(genre: RAGenre, bpm: Int)] = []
    private var activeIndex = 0
    private var beatTimer: DispatchSourceTimer?
    private var rotationTimer: DispatchSourceTimer?

    /// Timing runs off the main thread so scrolling doesn't pause beats.
    private let timingQueue = DispatchQueue(label: "com.whencetherave.genrebeat", qos: .userInteractive)

    private static let rotationInterval: TimeInterval = 10

    func start(genres: [RAGenre], enabled: Bool) {
        stop()
        guard enabled, !genres.isEmpty else { return }

        genreSlots = GenreBPMResolver.bpms(for: genres)
        activeIndex = 0
        activateCurrentGenre()

        guard genreSlots.count > 1 else { return }

        timingQueue.async { [weak self] in
            guard let self else { return }
            self.rotationTimer?.cancel()
            let timer = DispatchSource.makeTimerSource(queue: self.timingQueue)
            timer.schedule(
                deadline: .now() + Self.rotationInterval,
                repeating: Self.rotationInterval,
                leeway: .milliseconds(50)
            )
            timer.setEventHandler { [weak self] in
                self?.advanceGenre()
            }
            self.rotationTimer = timer
            timer.resume()
        }
    }

    func stop() {
        timingQueue.sync {
            beatTimer?.cancel()
            beatTimer = nil
            rotationTimer?.cancel()
            rotationTimer = nil
        }

        genreSlots = []
        activeIndex = 0
        activeGenreId = nil
        beatPulse = false
    }

    deinit {
        timingQueue.sync {
            beatTimer?.cancel()
            rotationTimer?.cancel()
        }
    }

    private func advanceGenre() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.genreSlots.count > 1 else { return }
            self.activeIndex = (self.activeIndex + 1) % self.genreSlots.count
            self.activateCurrentGenre()
        }
    }

    private func activateCurrentGenre() {
        guard activeIndex < genreSlots.count else { return }
        activeGenreId = genreSlots[activeIndex].genre.id
        startBeatTimer(bpm: genreSlots[activeIndex].bpm)
    }

    private func startBeatTimer(bpm: Int) {
        let interval = 60.0 / Double(bpm)
        let leeway = DispatchTimeInterval.milliseconds(max(1, Int(interval * 100)))

        timingQueue.async { [weak self] in
            guard let self else { return }
            self.beatTimer?.cancel()

            let timer = DispatchSource.makeTimerSource(queue: self.timingQueue)
            timer.schedule(deadline: .now() + interval, repeating: interval, leeway: leeway)
            timer.setEventHandler { [weak self] in
                self?.fireBeat()
            }
            self.beatTimer = timer
            timer.resume()
        }

        fireBeat()
    }

    private func fireBeat() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.beatPulse.toggle()
            HapticFeedback.playGenreBeat()
        }
    }
}
