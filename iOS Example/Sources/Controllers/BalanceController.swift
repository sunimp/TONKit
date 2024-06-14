import Combine
import SnapKit
import TonKit
import UIKit

class BalanceController: UIViewController {
    private let adapter: TonAdapter = Manager.shared.adapter
    private var cancellables = Set<AnyCancellable>()

    private let titlesLabel = UILabel()
    private let valuesLabel = UILabel()
    private let errorsLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Balance"

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        view.addSubview(titlesLabel)
        titlesLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(24)
        }

        titlesLabel.numberOfLines = 0
        titlesLabel.font = .systemFont(ofSize: 12)
        titlesLabel.textColor = .gray

        view.addSubview(valuesLabel)
        valuesLabel.snp.makeConstraints { make in
            make.top.equalTo(titlesLabel)
            make.trailing.equalToSuperview().inset(16)
        }

        valuesLabel.numberOfLines = 0
        valuesLabel.font = .systemFont(ofSize: 12)
        valuesLabel.textColor = .black

        view.addSubview(errorsLabel)
        errorsLabel.snp.makeConstraints { make in
            make.top.equalTo(titlesLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        errorsLabel.numberOfLines = 0
        errorsLabel.font = .systemFont(ofSize: 12)
        errorsLabel.textColor = .red

        Publishers.MergeMany(adapter.syncStatePublisher, adapter.transactionsSyncStatePublisher, adapter.balancePublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.sync()
            }
            .store(in: &cancellables)

        sync()
    }

    @objc func logout() {
        Manager.shared.logout()

        if let window = UIApplication.shared.keyWindow {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = UINavigationController(rootViewController: WordsController())
            })
        }
    }

    @objc func refresh() {
        adapter.refresh()
    }

    private func sync() {
        let syncStateString: String

        var errorTexts = [String]()

        switch adapter.syncState {
        case .synced:
            syncStateString = "Synced!"
        case let .syncing(progress):
            if let progress = progress {
                syncStateString = "Syncing \(Int(progress * 100)) %"
            } else {
                syncStateString = "Syncing"
            }
        case let .notSynced(error):
            syncStateString = "Not Synced"
            errorTexts.append("Sync Error: \(error)")
        }

        errorsLabel.text = errorTexts.joined(separator: "\n\n")

        titlesLabel.set(string: """
        Sync state:
        Balance:
        """, alignment: .left)

//        \(adapter.lastBlockHeight.map { "# \($0)" } ?? "n/a")
        valuesLabel.set(string: """
        \(syncStateString)
        \(adapter.balance) \(adapter.coin)
        """, alignment: .right)
    }
}