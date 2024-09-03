//
//  BalanceCell.swift
//  TONKit-Demo
//
//  Created by Sun on 2024/8/26.
//

import UIKit

import BigInt
import SnapKit
import TONKit

class TransactionCell: UITableViewCell {
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, HH:mm:ss")
        return formatter
    }()

    private let titlesLabel = UILabel()
    private let valuesLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(titlesLabel)
        titlesLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(24)
        }

        titlesLabel.numberOfLines = 0
        titlesLabel.font = .systemFont(ofSize: 12)
        titlesLabel.textColor = .gray
        titlesLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titlesLabel.setContentHuggingPriority(.required, for: .horizontal)

        contentView.addSubview(valuesLabel)
        valuesLabel.snp.makeConstraints { make in
            make.top.equalTo(titlesLabel)
            make.trailing.equalToSuperview().inset(16)
            make.leading.equalTo(titlesLabel.snp.trailing).offset(8)
        }

        valuesLabel.numberOfLines = 0
        valuesLabel.font = .systemFont(ofSize: 12)
        valuesLabel.textColor = .black
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(transaction: TransactionRecord, coin _: String, lastBlockHeight _: Int?) {
//        var confirmations = "n/a"

//        var contract: Contract? = nil
//
//        if let decoration = transaction.decoration as? NativeTransactionDecoration {
//            contract = decoration.contract
//        }

        titlesLabel.set(string: """
        Tx Hash:
        Date:
        inProgress:
        Decoration:
        Contract:
        """, alignment: .left)

        valuesLabel.set(string: """
        \(format(hash: transaction.transactionHash))
        \(TransactionCell.dateFormatter.string(from: Date(timeIntervalSince1970: Double(transaction.timestamp))))
        \(transaction.isInProgress)
        \(String(describing: transaction.decoration))
        """, alignment: .right)
//                    \(contract.flatMap { String(describing: type(of: $0)) } ?? "n/a")
    }

    private func format(hash: String) -> String {
        guard hash.count > 22 else {
            return hash
        }

        return "\(hash[..<hash.index(hash.startIndex, offsetBy: 10)])...\(hash[hash.index(hash.endIndex, offsetBy: -10)...])"
    }
}
