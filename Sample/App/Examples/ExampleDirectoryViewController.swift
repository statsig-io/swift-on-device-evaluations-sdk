import Foundation

import UIKit

let Examples: [(String, UIViewController)] = [
    // Swift
    ( "Basic (Swift)", BasicOnDeviceEvaluationsViewController() ),
    ( "Synchronous Init (Swift)", SynchronousInitViewController() ),
    ( "Statsig Client Events (Swift)", ClientEventsViewController() ),
    ( "Statsig Global User (Swift)", GlobalUserOnDeviceEvaluationsViewController() ),

    // Objective C
    ( "Basic (ObjC)", BasicOnDeviceEvaluationsViewControllerObjC() ),
    ( "Perf (ObjC)", PerfOnDeviceEvaluationsViewControllerObjC() ),
    ( "Statsig Client Events (ObjC)", ClientEventsViewControllerObjC() ),

]


class ExampleDirectoryEntryCell: UICollectionViewCell {
    let label: UILabel

    override init(frame: CGRect) {
        label = UILabel(frame: CGRectMake(10, 5, frame.width - 20, frame.height - 10))
        super.init(frame: frame)

        contentView.addSubview(label)
    }

    required init?(coder: NSCoder) { nil }
}

class ExampleDirectoryViewController: UIViewController {
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0

        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: layout
        )

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ExampleDirectoryEntryCell.self, forCellWithReuseIdentifier: "Cell")

        view.addSubview(collectionView)
    }
}

extension ExampleDirectoryViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        Examples.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "Cell",
            for: indexPath
        ) as! ExampleDirectoryEntryCell

        let (key, _) = Examples[indexPath.item]

        cell.label.text = key
        return cell
    }
}

extension ExampleDirectoryViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let (_, controller) = Examples[indexPath.item]
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ExampleDirectoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(
            width: view.frame.width,
            height: 40
        )
    }
}
