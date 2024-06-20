import BigInt
import Combine
import HsExtensions
import SnapKit
import TonKit
import TonSwift
import UIKit

class SendController: UIViewController {
    private let adapter: TonAdapter = Manager.shared.adapter
    private let estimatedFeeLimit: Int? = nil
    private var cancellables = Set<AnyCancellable>()

    private let addressTextField = UITextField()
    private let amountTextField = UITextField()
    private let gasPriceLabel = UILabel()
    private let sendButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Send TON"

        let addressLabel = UILabel()

        view.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.textColor = .gray
        addressLabel.text = "Address:"

        let addressTextFieldWrapper = UIView()

        view.addSubview(addressTextFieldWrapper)
        addressTextFieldWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(addressLabel.snp.bottom).offset(8)
        }

        addressTextFieldWrapper.borderWidth = 1
        addressTextFieldWrapper.borderColor = .black.withAlphaComponent(0.1)
        addressTextFieldWrapper.layer.cornerRadius = 8

        addressTextFieldWrapper.addSubview(addressTextField)
        addressTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        addressTextField.text = Configuration.shared.defaultSendAddress
        addressTextField.font = .systemFont(ofSize: 13)

        let amountLabel = UILabel()

        view.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(addressTextFieldWrapper.snp.bottom).offset(24)
        }

        amountLabel.font = .systemFont(ofSize: 14)
        amountLabel.textColor = .gray
        amountLabel.text = "Amount:"

        let amountTextFieldWrapper = UIView()

        view.addSubview(amountTextFieldWrapper)
        amountTextFieldWrapper.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(amountLabel.snp.bottom).offset(8)
        }

        amountTextFieldWrapper.borderWidth = 1
        amountTextFieldWrapper.borderColor = .black.withAlphaComponent(0.1)
        amountTextFieldWrapper.layer.cornerRadius = 8

        amountTextFieldWrapper.addSubview(amountTextField)
        amountTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        amountTextField.font = .systemFont(ofSize: 13)

        let ethLabel = UILabel()

        view.addSubview(ethLabel)
        ethLabel.snp.makeConstraints { make in
            make.leading.equalTo(amountTextFieldWrapper.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(amountTextFieldWrapper)
        }

        ethLabel.font = .systemFont(ofSize: 13)
        ethLabel.textColor = .black
        ethLabel.text = "TON"

        view.addSubview(gasPriceLabel)
        gasPriceLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(amountTextFieldWrapper.snp.bottom).offset(24)
        }

        gasPriceLabel.font = .systemFont(ofSize: 12)
        gasPriceLabel.textColor = .gray

        view.addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(gasPriceLabel.snp.bottom).offset(24)
        }

        sendButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        sendButton.setTitleColor(.systemBlue, for: .normal)
        sendButton.setTitleColor(.lightGray, for: .disabled)
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)

        addressTextField.addTarget(self, action: #selector(updateEstimatedFee), for: .editingChanged)
        amountTextField.addTarget(self, action: #selector(updateEstimatedFee), for: .editingChanged)

        adapter.tonKit.$updateState.sink { s in
            self.amountTextField.text = s
        }.store(in: &cancellables)
//        updateEstimatedFee()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc private func updateEstimatedFee() {
        guard let address = addressTextField.text?.trimmingCharacters(in: .whitespaces),
              let valueText = amountTextField.text,
              let value = Int(valueText),
              value > 0
        else {
            return
        }

        gasPriceLabel.text = "Loading..."

        Task { [weak self, adapter] in
            do {
                let fee = try await adapter.estimateFee(recipient: address, amount: BigUInt(value), comment: "")

                self?.sendButton.isEnabled = value > 0
                self?.gasPriceLabel.text = fee.description
            } catch {
                print(error)
                self?.gasPriceLabel.text = "Can't retrieve gas"
            }
        }
    }

    @objc private func send() {
        guard let addressHex = addressTextField.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }

        
        guard let validated = try? FriendlyAddress(string: addressHex) else {
            show(error: "Invalid address")
            return
        }
        
        let address = validated.address.toString(bounceable: true)

        guard let valueText = amountTextField.text, let value = BigUInt(valueText, radix: 10), value > 0 else {
            show(error: "Invalid amount")
            return
        }

        gasPriceLabel.text = "Sending..."

        Task { [weak self, adapter] in
            do {
                try await adapter.send(recipient: address, amount: value, comment: nil)
                self?.handleSuccess(address: address, amount: value)
            } catch {
                self?.show(error: "Send failed: \(error)")
            }
        }
    }

    @MainActor
    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    @MainActor
    private func handleSuccess(address: String, amount: BigUInt) {
        addressTextField.text = ""
        amountTextField.text = ""
        gasPriceLabel.text = ""

        let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
}
