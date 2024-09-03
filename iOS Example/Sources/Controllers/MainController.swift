//
//  ReceiveController.swift
//  TONKit-Demo
//
//  Created by Sun on 2024/8/26.
//

import UIKit

import TONKit

class MainController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        var controllers = [UIViewController]()

        let balanceNavigation = UINavigationController(rootViewController: BalanceController())
        balanceNavigation.tabBarItem.title = "Balance"
        balanceNavigation.tabBarItem.image = UIImage(named: "Balance Tab Bar Icon")
        controllers.append(balanceNavigation)

        let transactionsNavigation = UINavigationController(rootViewController: TransactionsController())
        transactionsNavigation.tabBarItem.title = "Transactions"
        transactionsNavigation.tabBarItem.image = UIImage(named: "Transactions Tab Bar Icon")
        controllers.append(transactionsNavigation)

        if !Manager.shared.tonKit.watchOnly {
            let sendNavigation = UINavigationController(rootViewController: SendController())
            sendNavigation.tabBarItem.title = "Send"
            sendNavigation.tabBarItem.image = UIImage(named: "Send Tab Bar Icon")
            controllers.append(sendNavigation)

            let trc20SendNavigation = UINavigationController(rootViewController: JettonSendController())
            trc20SendNavigation.tabBarItem.title = "Jetton Send"
            trc20SendNavigation.tabBarItem.image = UIImage(named: "Send Tab Bar Icon")
            controllers.append(trc20SendNavigation)
        }

        let receiveNavigation = UINavigationController(rootViewController: ReceiveController())
        receiveNavigation.tabBarItem.title = "Receive"
        receiveNavigation.tabBarItem.image = UIImage(named: "Receive Tab Bar Icon")
        controllers.append(receiveNavigation)

        viewControllers = controllers
    }
}

extension UILabel {
    func set(string: String, alignment: NSTextAlignment) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = alignment

        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

        attributedText = attributedString
    }
}
