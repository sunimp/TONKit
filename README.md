# TonKit.Swift

`TonKit.Swift` is a native(Swift) toolkit for TON network. it's based on TonKeeper libraries. It's implemented and used by [Unstoppable Wallet](https://github.com/horizontalsystems/unstoppable-wallet-ios), a multi-currency crypto wallet.

## Core Features

- [x] Local storage of account data (TON, JETTONS balances and transactions)
- [x] Synchronization over **HTTP/WebSocket**
- [x] **Watch accounts**. Restore with any address


## Usage

### Initialization

First you need to initialize an `TonKit.Kit` instance

```swift
import TonKit

//from TonSwift library
let address = try FriedlyAddress(string: "0x...")


let TonKit = try Kit.instance(
    type: .watch(address), 
    network: .mainnet, 
    walletId: "unique_wallet_id", 
    minLogLevel: .error
)
```

### Starting and Stopping

`TonKit.Kit` instance requires to be started with `start` command. This start the process of synchronization with the blockchain state.

```swift
TonKit.start()
TonKit.stop()
```

## Installation

### Swift Package Manager

[Swift Package Manager](https://www.swift.org/package-manager) is a dependency manager for Swift projects. You can install it with the following command:

```swift
dependencies: [
    .package(url: "https://github.com/horizontalsystems/TonKit.Swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## Prerequisites

* Xcode 10.0+
* Swift 5.5+
* iOS 15+


## Example Project

All features of the library are used in example project located in `iOS Example` folder. It can be referred as a starting point for usage of the library.

## License

The `TonKit.Swift` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/TonKit.Swift/blob/master/LICENSE).

