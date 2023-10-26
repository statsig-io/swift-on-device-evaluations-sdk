import UIKit
import Statsig

class BasicPrecomputedEvaluationsViewController: UIViewController {

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

        let client = StatsigPrecomputedEvaluationsClient.shared

        client.initialize(Constants.CLIENT_SDK_KEY, user: user) { err in
            if let err = err {
                print("Error \(err)")
                return
            }

            let result = client.checkGate("a_gate")
            print("Result: \(result == true ? "Pass": "Fail")")
        }

//        Statsig.start(sdkKey: Constants.CLIENT_SDK_KEY, user: user) { err in

//        }
    }
}

