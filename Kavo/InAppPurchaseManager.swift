import Foundation
import StoreKit

final class InAppPurchaseManager: NSObject {
    struct ProductItem {
        let product: SKProduct
        let coinAmount: Int

        var identifier: String { product.productIdentifier }
        var displayName: String {
            coinAmount > 0 ? "\(coinAmount)" : product.localizedTitle
        }
        var displayPrice: String {
            if let configuredPrice = InAppPurchaseManager.configuredUSDPrices[identifier] {
                return configuredPrice
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.currencyCode = "USD"
            return formatter.string(from: product.price) ?? "$\(product.price.stringValue)"
        }
    }

    enum State: Equatable {
        case idle
        case loadingProducts
        case purchasing(productID: String)
        case deferred(productID: String)
    }

    static let shared = InAppPurchaseManager()
    static let productsDidChange = Notification.Name("Kavo.IAP.ProductsDidChange")
    static let stateDidChange = Notification.Name("Kavo.IAP.StateDidChange")
    static let purchaseSucceeded = Notification.Name("Kavo.IAP.PurchaseSucceeded")
    static let purchaseFailed = Notification.Name("Kavo.IAP.PurchaseFailed")

    // MARK: - Product Configuration
    // Update these collections together when switching to the 10-product production environment.
    private static let configuredProductIdentifiers = [
        "vhsbfkerngovxbla",
        "ieakzidiqbnzxyxj",
        "nsvqjqzxdlumryye",
        "fcjiphudtngxvufc",
        "svrmayjuruphgegj",
        "atysvdhixxyupjft",
        "toushbwzimjvedwq",
        "putwwpqwrnanwncq",
        "neufdvzhzhpgqznf",
        "tbxnvjonzoslikqu",
    ]

    private static let configuredCoinAmounts: [String: Int] = [
        "vhsbfkerngovxbla": 400,
        "ieakzidiqbnzxyxj": 1_200,
        "nsvqjqzxdlumryye": 2_450,
        "fcjiphudtngxvufc": 4_900,
        "svrmayjuruphgegj": 6_400,
        "atysvdhixxyupjft": 9_800,
        "toushbwzimjvedwq": 14900,
        "putwwpqwrnanwncq": 24500,
        "neufdvzhzhpgqznf": 34500,
        "tbxnvjonzoslikqu": 49000,
    ]

    private static let configuredUSDPrices: [String: String] = [
        "vhsbfkerngovxbla": "$0.99",
        "ieakzidiqbnzxyxj": "$1.99",
        "nsvqjqzxdlumryye": "$4.99",
        "fcjiphudtngxvufc": "$9.99",
        "svrmayjuruphgegj": "$12.99",
        "atysvdhixxyupjft": "$19.99",
        "toushbwzimjvedwq": "$29.99",
        "putwwpqwrnanwncq": "$49.99",
        "neufdvzhzhpgqznf": "$69.99",
        "tbxnvjonzoslikqu": "$99.99",
    ]

    private var productsRequest: SKProductsRequest?
    private var isObservingQueue = false
    private var processedTransactionIDs: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: processedTransactionsKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: processedTransactionsKey)
        }
    }

    private(set) var products: [ProductItem] = []
    private(set) var state: State = .idle {
        didSet {
            guard state != oldValue else { return }
            post(Self.stateDidChange)
        }
    }

    var productIdentifiers: [String] {
        Self.configuredProductIdentifiers
    }

    private var coinAmounts: [String: Int] {
        Self.configuredCoinAmounts
    }

    private var processedTransactionsKey: String {
        "Kavo.IAP.ProcessedTransactions.\(AuthSessionStore.accountIdentifier)"
    }

    private override init() {
        super.init()
    }

    deinit {
        if isObservingQueue {
            SKPaymentQueue.default().remove(self)
        }
    }

    func start() {
        if !isObservingQueue {
            SKPaymentQueue.default().add(self)
            isObservingQueue = true
        }
        if products.isEmpty, state != .loadingProducts {
            fetchProducts()
        }
    }

    func fetchProducts() {
        let identifiers = Set(productIdentifiers)
        guard !identifiers.isEmpty else {
            products = []
            state = .idle
            post(Self.productsDidChange)
            postFailure("No in-app purchase product identifiers are configured.")
            return
        }
        productsRequest?.cancel()
        state = .loadingProducts
        let request = SKProductsRequest(productIdentifiers: identifiers)
        productsRequest = request
        request.delegate = self
        request.start()
    }

    func purchase(productID: String) {
        guard state == .idle else { return }
        guard SKPaymentQueue.canMakePayments() else {
            postFailure("In-app purchases are disabled on this device.")
            return
        }
        guard let item = products.first(where: { $0.identifier == productID }) else {
            postFailure("This product is currently unavailable.")
            return
        }
        state = .purchasing(productID: productID)
        SKPaymentQueue.default().add(SKPayment(product: item.product))
    }

    private func complete(_ transaction: SKPaymentTransaction, queue: SKPaymentQueue) {
        let productID = transaction.payment.productIdentifier
        let transactionID = transaction.transactionIdentifier
        var processed = processedTransactionIDs
        let wasAlreadyProcessed = transactionID.map(processed.contains) ?? false

        if !wasAlreadyProcessed {
            let amount = coinAmount(for: productID)
            guard amount > 0 else {
                queue.finishTransaction(transaction)
                state = .idle
                postFailure("The coin amount for this product is not configured.")
                return
            }
            MockRepository.shared.recharge(coins: amount)
            if let transactionID {
                processed.insert(transactionID)
                processedTransactionIDs = processed
            }
            post(
                Self.purchaseSucceeded,
                userInfo: ["productID": productID, "coinAmount": amount]
            )
        }
        queue.finishTransaction(transaction)
        state = .idle
    }

    private func coinAmount(for productID: String) -> Int {
        if let amount = coinAmounts[productID] {
            return amount
        }
        guard let product = products.first(where: { $0.identifier == productID })?.product else {
            return 0
        }
        let source = "\(product.localizedTitle) \(product.localizedDescription)"
        let digits = source.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        return digits.max() ?? 0
    }

    private func postFailure(_ message: String) {
        post(Self.purchaseFailed, userInfo: ["message": message])
    }

    private func post(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: self, userInfo: userInfo)
        }
    }
}

extension InAppPurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let order = Dictionary(uniqueKeysWithValues: productIdentifiers.enumerated().map { ($0.element, $0.offset) })
        products = response.products
            .map { ProductItem(product: $0, coinAmount: coinAmount(for: $0.productIdentifier)) }
            .sorted {
                order[$0.identifier, default: .max] < order[$1.identifier, default: .max]
            }
        productsRequest = nil
        state = .idle
        post(Self.productsDidChange)
        if products.isEmpty {
            postFailure("No available products were returned by the App Store.")
        } else if !response.invalidProductIdentifiers.isEmpty {
            postFailure("Some in-app purchase products are unavailable in the current environment.")
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        productsRequest = nil
        state = .idle
        postFailure(error.localizedDescription)
    }
}

extension InAppPurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if StoreKit1PurchaseManager.KAInterCentralDisplayTS.KAThreeArsenalQuizzesTS(transaction.payment.productIdentifier) {
                continue
            }
            switch transaction.transactionState {
            case .purchased:
                complete(transaction, queue: queue)
            case .failed:
                queue.finishTransaction(transaction)
                state = .idle
                let error = transaction.error as? SKError
                if error?.code != .paymentCancelled {
                    postFailure(error?.localizedDescription ?? "The purchase failed.")
                }
            case .deferred:
                state = .deferred(productID: transaction.payment.productIdentifier)
            case .purchasing:
                state = .purchasing(productID: transaction.payment.productIdentifier)
            case .restored:
                // Recharge products are consumables. A restored transaction is only finished.
                queue.finishTransaction(transaction)
                state = .idle
            @unknown default:
                state = .idle
            }
        }
    }
}
