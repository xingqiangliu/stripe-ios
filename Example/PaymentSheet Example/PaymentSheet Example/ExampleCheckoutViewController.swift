//
//  ExampleCheckoutViewController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 12/4/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import Foundation
import UIKit
import Stripe

class ExampleCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!
    var paymentSheet: PaymentSheet?
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")! // An example backend endpoint

    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        // MARK: Fetch the PaymentIntent and Customer information from the backend
        let json: [String: Any] = [:] // Your app might put a list of product ids here
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                  let customerId = json["customerId"] as? String,
                  let customerEphemeralKeySecret = json["customerEphemeralKeySecret"] as? String,
                  let paymentIntentClientSecret = json["paymentIntentClientSecret"] as? String,
                  let publishableKey = json["publishableKey"] as? String,
                  let self = self else {
                // Handle error
                return
            }
            // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
            StripeAPI.defaultPublishableKey = publishableKey

            // MARK: Create a PaymentSheet instance
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Example, Inc."
            configuration.applePay = .init(merchantId: "com.foo.example", merchantCountryCode: "US")
            configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)

            DispatchQueue.main.async {
                self.buyButton.isEnabled = true
            }
        })
        task.resume()
    }

    @objc
    func didTapCheckoutButton() {
        // MARK: Start the checkout process
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.displayAlert("Payment succeeded!")
            case .canceled:
                return
            case .failed(let error, _):
                self.displayAlert("Payment failed: \n\(error.localizedDescription)")
            }
        }
    }

    func displayAlert(_ message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}
