import UIKit
extension UIFont {
    static let ysMedium20 = UIFont(name: "YSDisplay-Medium", size: 20)
    static let ysBold23 = UIFont(name: "YSDisplay-Bold", size: 23)
}
final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var questionTitleLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    
    
    private var currentQuestion: QuizQuestion?
    private lazy var alertPresenter = AlertPresenter(viewController: self)
    
    private var presenter: MovieQuizPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = MovieQuizPresenter(viewController: self)
        textLabel.font = UIFont.ysBold23
        counterLabel.font = UIFont.ysMedium20
        yesButton.titleLabel?.font = UIFont.ysMedium20
        noButton.titleLabel?.font = UIFont.ysMedium20
        questionTitleLabel.font = UIFont.ysMedium20
        imageView.layer.cornerRadius = 20
        
    }
    
    func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        yesButton.isEnabled = true
        noButton.isEnabled = true
       
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        yesButton.isEnabled = false
        noButton.isEnabled  = false
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    func showAlert(model: AlertModel) {
        alertPresenter.showAlert(model: model)
    }
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    func show(quiz result: QuizResultsViewModel) {
        let message = presenter.makeResultsMessage()
        let alertModel = AlertModel(
            title: result.title,
            message: message,
            buttonText: "Сыграть ещё раз"
        ) { [weak self] in
            guard let self = self else { return }
            self.presenter.restartGame()
        }

        alertPresenter.showAlert(model: alertModel)
    }
    
    func showNetworkError(message: String) {
        
        let alertModel = AlertModel(
            title: "Что-то пошло не так(",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in
            guard let self = self else { return }
            self.showLoadingIndicator()
            
            if self.presenter.currentQuestionIndex == 0 {
                self.presenter.restartGame()
            } else {
                self.presenter.requestNextQuestion()
            }
        }

        alertPresenter.showAlert(model: alertModel)
    }
    }

