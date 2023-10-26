import UIKit
import Statsig

class BasicOnDeviceEvaluationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let user = StatsigUser(userID: "a-user")
        user.custom = StatsigUserValueMap([
            "name": "jkw",
            "speed": 1.2,
            "verified": true,
            "visits": 3,
            "tags": ["cool", "rad", "neat"],
        ])

        let client = StatsigOnDeviceEvaluationsClient.shared

        client.initialize(Constants.CLIENT_SDK_KEY) { [weak client] err in
            if let err = err {
                print("Error \(err)")
            }

            let result = client?.getFeatureGate("a_gate", user)
            print("Result: \(result?.value == true ? "Pass": "Fail")")
        }
    }


}

