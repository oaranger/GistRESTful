//
//  LoginViewController.swift
//  swiftREST
//
//  Created by Binh Huynh on 11/26/18.
//  Copyright © 2018 Binh Huynh. All rights reserved.
//

import UIKit

protocol LoginViewDelegate: class {
    func didTapLoginButton()
}

class LoginViewController: UIViewController {
    weak var delegate: LoginViewDelegate?
    @IBAction func tappedLoginButton() {
        print("button was tapped")
        // TODO: implement
        delegate?.didTapLoginButton()
    }
}
