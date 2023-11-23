import UIKit
import StatsigOnDeviceEvaluations

class GlobalUserOnDeviceEvaluationsViewController: UIViewController {
    let label = UILabel(frame: CGRectMake(0, 0, 100, 40))

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Global Statsig User"
        view.backgroundColor = UIColor.white

        addLabel("Loading...")

        Statsig.shared.initialize(Constants.CLIENT_SDK_KEY) { [weak self] err in
            DispatchQueue.main.async {
                self?.onInitialized(err)
            }
        }
    }

    private func onInitialized(_ error: Error?) {
        if let error = error {
            let message = "Error \(error)"
            label.text = message
            print(message)
            return
        }

        let user = StatsigUser(userID: "a-user")

        _ = Statsig.shared.checkGate("partial_gate") // Prints a "No user" error

        Statsig.shared.setGlobalUser(user)

        let gate = Statsig.shared.checkGate("a_gate")
        view.backgroundColor = gate ? UIColor.systemGreen : UIColor.systemRed

        let experiment = Statsig.shared.getExperiment("an_experiment")
        label.text = experiment.value["a_string"] as? String ?? ""
    }

    private func addLabel(_ initialText: String) {
        label.text = initialText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

