import UIKit
import StatsigOnDeviceEvaluations

class ClientEventsViewController: UIViewController {
    let statsig = Statsig()

    var user = StatsigUser(userID: "a-user")
    var receivedEvents: [(Int64, StatsigClientEvent, [String: String])] = []
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupNavbar()

        statsig.addListener(self)

        _ = statsig.checkGate("a_gate") // Fires "Uninitialized" error

        statsig.initialize(Constants.CLIENT_SDK_KEY)
    }
}

extension ClientEventsViewController: StatsigListening {
    func onStatsigClientEvent(
        _ event: StatsigOnDeviceEvaluations.StatsigClientEvent,
        _ eventData: [String : Any]
    ) {
        var data: [String: String] = [:]

        for (key, value) in eventData {
            if let value = value as? String {
                data[key] = value
            }

            else if let value = value as? Data {
                data[key] = String(data: value, encoding: .utf8)
            }

            else {
                data[key] = "\(value)"
            }
        }

        receivedEvents.append((Time.now(), event, data))
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}


extension ClientEventsViewController: UITableViewDataSource {
    func setupTableView() {
        tableView = UITableView(frame: view.bounds)
        tableView.dataSource = self
        view.addSubview(tableView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        receivedEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")

        let (time, event, data) = receivedEvents[indexPath.item]
        cell.textLabel?.text = "\(time): \(event)"

        let formatted = data
            .map { (key, value) in
                let result = "\(key): \(value)"
                return result.prefix(200)
            }
            .sorted()
            .joined(separator: "\n")

        cell.detailTextLabel?.text = "\(formatted)"
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        return cell
    }
}

extension ClientEventsViewController {
    func setupNavbar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Log Event",
            style: .plain,
            target: self,
            action: #selector(logEventTapped)
        )
    }

    @objc func logEventTapped() {
        statsig.logEvent(StatsigEvent(eventName: "my_custom_event"), user)
    }
}
