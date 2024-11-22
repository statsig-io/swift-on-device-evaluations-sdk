import UIKit
import StatsigOnDeviceEvaluations


class TypedStatsigViewController: UIViewController {
    let user = StatsigUser(userID: "a-user")
    let statsig = Statsig()
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statsig.initialize(Constants.CLIENT_SDK_KEY) { [weak self] err in
            if let err = err {
                print("Error \(err)")
            }
            
            DispatchQueue.main.async {
                self?.render()
            }
        }
    }
    
    func render() {
        var texts = ["-- Strict Typing --"]

        evalAndAppendResults(texts: &texts)

        texts.append("-- After Empty Specs Update --")
        
        // Update specs to be entirely empty
        let path = Bundle.main.path(forResource: "EmptySynchronousSpecs", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = NSData(contentsOf: url)!
        
        _ = statsig.updateSync(updatedSpecs: data)

        evalAndAppendResults(texts: &texts)

        // Render labels
        let labels = texts.map { createLabel(text: $0) }
        labels.forEach { view.addSubview($0) }
        setupConstraints(for: labels)
    }
    
    private func evalAndAppendResults(texts: inout [String]) {
        // Get a Feature Gate using strict typing
        let aGate = statsig.typed.getFeatureGate(SdkDemoGates.aGate, user)
        texts.append("\(aGate.name): \(aGate.value ? "Pass": "Fail")")
        
        
        // Get an Experiment (with params) using strict typing
        let anotherExperiment = statsig.typed.getExperiment(SdkDemoExperiments.AnotherExperiment(), user)
        let value = anotherExperiment.value
        texts.append("\(anotherExperiment.name): \(value?.aString ?? "Not Found") - \(value?.aBool == true ? "Pass" : "Fail")")

        // Get an Experiment using strict typing
        let anExperiment = statsig.typed.getExperiment(SdkDemoExperiments.AnExperiment(), user)
        switch anExperiment.group {
        case .test:
            texts.append("\(anExperiment.name): Test Group")
            break
            
        case .none:
            fallthrough
        case .control:
            texts.append("\(anExperiment.name): Control Group")
            break
        }
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func setupConstraints(for labels: [UILabel]) {
        guard !labels.isEmpty else { return }
        
        var constraints: [NSLayoutConstraint] = []
        
        for (index, label) in labels.enumerated() {
            if index == 0 {
                // First label is centered vertically
                constraints.append(contentsOf: setupLabelConstraints(label, centerYOffset: -CGFloat(20 * (labels.count - 1))))
            } else {
                // Subsequent labels are positioned relative to the previous label
                constraints.append(contentsOf: setupLabelConstraints(label, topAnchor: labels[index - 1].bottomAnchor))
            }
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupLabelConstraints(_ label: UILabel, centerYOffset: CGFloat? = nil, topAnchor: NSLayoutYAxisAnchor? = nil) -> [NSLayoutConstraint] {
        var constraints = [
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ]
        
        if let centerYOffset = centerYOffset {
            constraints.append(label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: centerYOffset))
        } else if let topAnchor = topAnchor {
            constraints.append(label.topAnchor.constraint(equalTo: topAnchor, constant: 20))
        }
        
        return constraints
    }
}

