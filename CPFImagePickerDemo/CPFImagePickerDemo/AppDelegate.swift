//
//  AppDelegate.swift
//  CPFImagePickerDemo
//
//  Created by Aaron on 2022/12/7.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = .white
        self.window?.rootViewController = {
            let controller = UINavigationController(rootViewController: ViewController()).then {
                $0.isNavigationBarHidden = false
            }
            return controller
        }()
        self.window?.makeKeyAndVisible()

        return true
    }
}
