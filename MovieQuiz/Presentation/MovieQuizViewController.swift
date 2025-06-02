import UIKit
extension UIFont {
    static let ysMedium20 = UIFont(name: "YSDisplay-Medium", size: 20)
    static let ysBold23 = UIFont(name: "YSDisplay-Bold", size: 23)
}
final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate  {
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var questionTitleLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol!
    private var currentQuestion: QuizQuestion?
    private lazy var alertPresenter = AlertPresenter(viewController: self)
    private var statisticService: StatisticServiceProtocol = StatisticService()
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.font = UIFont.ysBold23
        counterLabel.font = UIFont.ysMedium20
        yesButton.titleLabel?.font = UIFont.ysMedium20
        noButton.titleLabel?.font = UIFont.ysMedium20
        questionTitleLabel.font = UIFont.ysMedium20
        imageView.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticService()
        questionFactory.loadData()
    }
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            showNetworkError(message:"Что-то пошло не так(")
            return
        }
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.show(quiz: viewModel)
            self.hideLoadingIndicator()
            self.imageView.image = viewModel.image
            self.textLabel.text = viewModel.question
            self.counterLabel.text = viewModel.questionNumber
        }
    }
    func didStartLoadingQuestion() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    func didLoadDataFromServer() {
        questionFactory.requestNextQuestion()
    }
    func didFailToLoadData(with error: Error) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        showNetworkError(message: error.localizedDescription)
    }
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
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
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
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
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Что-то пошло не так(",
                               message: "Невозможно загрузить данные",
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            self.showLoadingIndicator()
            self.questionFactory.loadData()
        }
        
        alertPresenter.showAlert(model: model)
    }
    
}
