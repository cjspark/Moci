import Foundation

// FSRS-4.5 spaced repetition algorithm
// Reference: https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm
enum FSRS {
    static let requestedRetention: Double = 0.9

    // Default FSRS-4.5 weights
    private static let w: [Double] = [
        0.4072, 1.1829, 3.1262, 15.4722,
        7.2102, 0.5316,
        1.0651, 0.0589,
        1.5330, 0.1544, 1.0070,
        1.9395, 0.1100, 0.2900, 2.2700,
        0.1500, 2.9898,
        0.5100, 0.3400
    ]

    private static let decay: Double = -0.5
    // factor = 0.9^(1/decay) - 1 = 19/81 ≈ 0.2346
    private static let factor: Double = pow(0.9, 1.0 / decay) - 1

    // Probability of recall after elapsedDays given stability
    static func retrievability(elapsedDays: Double, stability: Double) -> Double {
        guard stability > 0 else { return 0 }
        return pow(1.0 + factor * elapsedDays / stability, decay)
    }

    // Optimal interval (days) for requestedRetention
    static func nextInterval(stability: Double) -> Int {
        let interval = stability / factor * (pow(requestedRetention, 1.0 / decay) - 1)
        return max(1, Int(interval.rounded()))
    }

    private static func initStability(_ rating: Int) -> Double {
        w[rating - 1]
    }

    private static func initDifficulty(_ rating: Int) -> Double {
        let d = w[4] - exp(w[5] * Double(rating - 1)) + 1
        return min(max(d, 1.0), 10.0)
    }

    private static func nextDifficulty(_ d: Double, rating: Int) -> Double {
        let d04 = initDifficulty(4)
        let nextD = d - w[6] * Double(rating - 3)
        let result = w[7] * d04 + (1 - w[7]) * nextD
        return min(max(result, 1.0), 10.0)
    }

    private static func nextRecallStability(d: Double, s: Double, r: Double, rating: Int) -> Double {
        let hardPenalty = rating == 2 ? w[15] : 1.0
        let easyBonus  = rating == 4 ? w[16] : 1.0
        return s * (exp(w[8]) * (11 - d) * pow(s, -w[9]) * (exp(w[10] * (1 - r)) - 1) * hardPenalty * easyBonus + 1)
    }

    private static func nextForgetStability(d: Double, s: Double, r: Double) -> Double {
        w[11] * pow(d, -w[12]) * (pow(s + 1, w[13]) - 1) * exp(w[14] * (1 - r))
    }

    static func schedule(card: Card, rating: Int, now: Date = Date()) -> FSRSResult {
        let elapsedDays: Double = card.lastReview.map {
            max(0, now.timeIntervalSince($0) / 86400.0)
        } ?? 0

        let r: Double = (card.stability > 0 && card.fsrsState != .new)
            ? retrievability(elapsedDays: elapsedDays, stability: card.stability)
            : 0

        var newState      = card.fsrsState
        var newStability  = card.stability
        var newDifficulty = card.difficulty
        var newReps       = card.reps
        var newLapses     = card.lapses

        switch card.fsrsState {
        case .new:
            newStability  = initStability(rating)
            newDifficulty = initDifficulty(rating)
            if rating == 1 {
                newState = .learning
            } else {
                newState = .review
                newReps += 1
            }

        case .learning, .relearning:
            if rating == 1 {
                // Stay in learning state
            } else {
                newState = .review
                newReps += 1
                if newStability <= 0 { newStability = initStability(max(rating, 2)) }
            }

        case .review:
            newDifficulty = nextDifficulty(card.difficulty, rating: rating)
            if rating == 1 {
                newState     = .relearning
                newLapses   += 1
                newStability = nextForgetStability(d: card.difficulty, s: card.stability, r: r)
            } else {
                newReps     += 1
                newStability = nextRecallStability(d: card.difficulty, s: card.stability, r: r, rating: rating)
            }
        }

        let scheduledDays: Int
        let newDue: Date
        let dayStart = Calendar.current.startOfDay(for: now)

        switch newState {
        case .learning, .relearning:
            scheduledDays = 0
            newDue = now.addingTimeInterval(10 * 60) // 10 minutes
        case .new:
            scheduledDays = 0
            newDue = now
        case .review:
            scheduledDays = nextInterval(stability: newStability)
            newDue = dayStart.addingTimeInterval(Double(scheduledDays) * 86400)
        }

        return FSRSResult(
            due: newDue,
            stability: newStability,
            difficulty: newDifficulty,
            state: newState,
            reps: newReps,
            lapses: newLapses,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays
        )
    }
}
