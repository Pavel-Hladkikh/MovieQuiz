import Foundation
import UIKit

    final class MovieQuizPresenter {

    let questionsAmount = 10
    private(set) var currentQuestionIndex = 0
    var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewControllerProtocol?
    var questionFactory: QuestionFactoryProtocol?
    private var correctAnswers: Int = 0
    private let statisticService: StatisticServiceProtocol = StatisticService()
        init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
       
        func requestNextQuestion() {
            questionFactory?.requestNextQuestion()
        }
        
        func restartGame() {
            currentQuestionIndex = 0
            correctAnswers = 0
            viewController?.showLoadingIndicator()
            questionFactory?.loadData()
        }
        func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
        func yesButtonClicked() {
            didAnswer(isYes: true)
        }

        func noButtonClicked() {
            didAnswer(isYes: false)
        }
    
        private func didAnswer(isYes: Bool) {
            guard let question = currentQuestion else { return }
            let isCorrect = (isYes == question.correctAnswer)
            proceedWithAnswer(isCorrect: isCorrect)
        }
        func didAnswer(isCorrectAnswer: Bool) {
            if isCorrectAnswer {
                correctAnswers += 1
            }
        }
       func proceedToNextQuestionOrResults() {
           if self.isLastQuestion() {
                    statisticService.store(correct: correctAnswers,
                                            total: questionsAmount)
                let resultText = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
                let gamesText = "Количество сыгранных квизов: \(statisticService.gamesCount)"
                let best = statisticService.bestGame
                let recordText = "Рекорд: \(best.correct)/\(best.total) (\(best.date.dateTimeString))"
                let accuracy = String(format: "%.2f", statisticService.totalAccuracy)
                let accuracyText = "Средняя точность: \(accuracy)%"
                let message = [
                    resultText,
                    gamesText,
                    recordText,
                    accuracyText
                ].joined(separator: "\n")
                let alertModel = AlertModel(
                    title: "Этот раунд окончен!",
                    message: message,
                    buttonText: "Сыграть ещё раз"
                ) { [weak self] in
                    guard let self = self else { return }
                    self.resetQuestionIndex()
                                self.correctAnswers = 0
                                self.questionFactory?.requestNextQuestion()
                            }
                            viewController?.showAlert(model: alertModel)
            } else {
                switchToNextQuestion()
                questionFactory?.requestNextQuestion()
            }
        }
        func makeResultsMessage() -> String {
            
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            
            let bestGame = statisticService.bestGame
            let totalGamesLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
            let currentResultLine = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
            let bestGameLine = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))"
            let accuracyLine = "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"

            
            
            return [
                currentResultLine,
                totalGamesLine,
                bestGameLine,
                accuracyLine
            ].joined(separator: "\n")
        }
        func proceedWithAnswer(isCorrect: Bool) {
                didAnswer(isCorrectAnswer: isCorrect)
                
                viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self else { return }
                    self.proceedToNextQuestionOrResults()
                }
            }

}
extension MovieQuizPresenter: QuestionFactoryDelegate {
    func didStartLoadingQuestion() {

           viewController?.showLoadingIndicator()
       }
       
       func didLoadDataFromServer() {
           
           viewController?.hideLoadingIndicator()
           questionFactory?.requestNextQuestion()
       }
       
       func didFailToLoadData(with error: Error) {
        
           viewController?.hideLoadingIndicator()
           viewController?.showNetworkError(message: "Невозможно загрузить данные")
       }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            
            viewController?.showNetworkError(message: "Невозможно загрузить данные")
            return
        }
        
        currentQuestion = question
        
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.hideLoadingIndicator()
            self?.viewController?.show(quiz: viewModel)
        }
    }
}

