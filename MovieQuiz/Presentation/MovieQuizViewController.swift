import UIKit
extension UIFont {
    static let ysMedium20 = UIFont(name: "YSDisplay-Medium", size: 20)
    static let ysBold23 = UIFont(name: "YSDisplay-Bold", size: 23)
}
final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate  {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var questionTitleLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount: Int = 10
    private let questionFactory: QuestionFactoryProtocol = QuestionFactory()
    private var currentQuestion: QuizQuestion?
    private lazy var alertPresenter = AlertPresenter(viewController: self)
    private let statisticService: StatisticServiceProtocol = StatisticService()
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.font = UIFont.ysBold23
        counterLabel.font = UIFont.ysMedium20
        yesButton.titleLabel?.font = UIFont.ysMedium20
        noButton.titleLabel?.font = UIFont.ysMedium20
        questionTitleLabel.font = UIFont.ysMedium20
        questionFactory.setup(delegate: self)
        questionFactory.requestNextQuestion()
    }
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    private func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            let resultText   = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
            let gamesText    = "Количество сыгранных квизов: \(statisticService.gamesCount)"
            let best         = statisticService.bestGame
            let recordText   = "Рекорд: \(best.correct)/\(best.total) (\(best.date.dateTimeString))"
            let accuracy     = String(format: "%.2f", statisticService.totalAccuracy)
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
                self.currentQuestionIndex = 0
                self.correctAnswers       = 0
                self.questionFactory.requestNextQuestion()
            }
            alertPresenter.showAlert(model: alertModel)
        } else {
            currentQuestionIndex += 1
            questionFactory.requestNextQuestion()
        }
    }
    private func showAnswerResult(isCorrect: Bool) {
        yesButton.isEnabled = false
        noButton.isEnabled = false
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self]  in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
}
