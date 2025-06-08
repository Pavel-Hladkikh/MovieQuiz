import Foundation
import UIKit
final class AlertPresenter {
    private weak var viewController: UIViewController?
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    func showAlert(model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert)
        alert.view.accessibilityIdentifier = "Game results"
        let action = UIAlertAction(title: model.buttonText, style: .default) { _ in
            model.completion()
        }
        action.accessibilityIdentifier = "firstMatch"
        alert.addAction(action)
        viewController?.present(alert, animated: true)
    }
}
