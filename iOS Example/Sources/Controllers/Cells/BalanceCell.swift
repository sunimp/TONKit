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

class BalanceCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(12)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .gray

        contentView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(12)
        }

        valueLabel.numberOfLines = 0
        valueLabel.font = .systemFont(ofSize: 12)
        valueLabel.textColor = .black
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, value: BigUInt) {
        titleLabel.set(string: format(hash: title), alignment: .left)
        valueLabel.set(string: value.description, alignment: .right)
    }
    
    private func format(hash: String) -> String {
        guard hash.count > 22 else {
            return hash
        }

        return "\(hash[..<hash.index(hash.startIndex, offsetBy: 10)])...\(hash[hash.index(hash.endIndex, offsetBy: -10)...])"
    }
}
