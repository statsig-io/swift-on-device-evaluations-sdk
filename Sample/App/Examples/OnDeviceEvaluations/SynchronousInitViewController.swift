import UIKit
import StatsigOnDeviceEvaluations

class SynchronousInitViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let user = StatsigUser(userID: "a-user")
        let client = StatsigOnDeviceEvaluationsClient.shared

        let path = Bundle.main.path(forResource: "SynchronousSpecs", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = NSData(contentsOf: url)!

        let error = client.initializeSync(
            Constants.CLIENT_SDK_KEY,
            initialSpecs: data
        )

        if let err = error {
            print("Error: \(err)")
            view.backgroundColor = UIColor.systemRed
        }
        else {
            let result = client.checkGate("test_gate", user)
            print("Result: \(result ? "Pass" : "Fail")")
            view.backgroundColor = UIColor.systemGreen
        }

    }
}

