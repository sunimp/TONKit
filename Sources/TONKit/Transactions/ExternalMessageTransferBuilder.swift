//
//  ExternalMessageTransferBuilder.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import Foundation
import TONSwift

public struct ExternalMessageTransferBuilder {
    // MARK: Lifecycle

    private init() { }

    // MARK: Static Functions

    public static func externalMessageTransfer(
        contract: WalletContract,
        sender: Address,
        sendMode: SendMode = .walletDefault(),
        seqno: UInt64,
        internalMessages: [MessageRelaxed],
        timeout: UInt64?,
        signer: WalletTransferSigner
    ) throws
        -> String {
        let transferData = WalletTransferData(
            seqno: seqno,
            messages: internalMessages,
            sendMode: sendMode,
            timeout: timeout
        )

        let transfer = try contract.createTransfer(args: transferData, messageType: .ext)
        let signedTransfer = try transfer.signMessage(signer: signer)
        let body = Builder()
        try body.store(data: signedTransfer)
        try body.store(transfer.signingMessage)
        let transferCell = try body.endCell()

        let externalMessage = Message.external(
            to: sender,
            stateInit: contract.stateInit,
            body: transferCell
        )

        let cell = try Builder().store(externalMessage).endCell()
        return try cell.toBoc().base64EncodedString()
    }
}
