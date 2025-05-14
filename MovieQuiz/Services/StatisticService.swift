import Foundation
final class StatisticService {
    private let storage: UserDefaults = .standard
    private enum Keys: String {
        case correctAnswers
        case totalQuestions
        case gamesCount
        case bestGameCorrect = "bestGame.correct"
        case bestGameTotal   = "bestGame.total"
        case bestGameDate    = "bestGame.date"
    }
}
extension StatisticService: StatisticServiceProtocol {
    var totalAccuracy: Double {
        let correctAnswers = storage.integer(forKey: Keys.correctAnswers.rawValue)
        let totalQuestions = storage.integer(forKey: Keys.totalQuestions.rawValue)
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    var gamesCount: Int{
        get { storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set { storage.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    var bestGame: GameResult {
        get {
            let correct = storage.integer(forKey: Keys.bestGameCorrect.rawValue)
            let total = storage.integer(forKey: Keys.bestGameTotal.rawValue)
            let date = storage.object(forKey: Keys.bestGameDate.rawValue) as? Date ?? Date()
            return GameResult(correct: correct, total: total, date: date)
        }
        set {
            storage.set(newValue.correct, forKey: Keys.bestGameCorrect.rawValue)
            storage.set(newValue.total,   forKey: Keys.bestGameTotal.rawValue)
            storage.set(newValue.date,    forKey: Keys.bestGameDate.rawValue)
        }
    }
    func store(correct count: Int, total amount: Int){
        gamesCount += 1
        let prevCorrect = storage.integer(forKey: Keys.correctAnswers.rawValue)
        storage.set(prevCorrect + count, forKey: Keys.correctAnswers.rawValue)
        let prevTotal = storage.integer(forKey: Keys.totalQuestions.rawValue)
        storage.set(prevTotal + amount, forKey: Keys.totalQuestions.rawValue)
        if count > bestGame.correct {
            bestGame = GameResult(correct: count,
                                  total: amount,
                                  date: Date())
        }
    }
}
