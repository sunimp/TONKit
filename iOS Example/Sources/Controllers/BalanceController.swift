//
//  WordsController.swift
//  TonKit-Demo
//
//  Created by Sun on 2024/8/26.
//

import Combine
import UIKit

import SnapKit
import TonKit
import TonSwift
import UIExtensions

class BalanceController: UIViewController {
    private let adapter: TonAdapter = Manager.shared.adapter
    private var cancellables = Set<AnyCancellable>()

    private let titlesLabel = UILabel()
    private let valuesLabel = UILabel()
    private let errorsLabel = UILabel()
    
    private let tableView = UITableView()
    private var balances = [JettonBalance]()

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
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(errorsLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(forClass: BalanceCell.self)

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

        if let window = UIWindow.keyWindow {
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

        tableView.reloadData()
    }
}

extension BalanceController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adapter.jettons.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.backgroundColor = .white
            
            let jettons = adapter.jettons
            guard jettons.count > indexPath.row else { return }
            let jetton = jettons[indexPath.row]
            
            cell.bind(title: jetton.address.toRaw(), value: adapter.jettonBalance(address: jetton.address))
        }
    }
}
