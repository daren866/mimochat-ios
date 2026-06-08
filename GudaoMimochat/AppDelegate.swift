import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "gdmimo" {
            NotificationCenter.default.post(name: NSNotification.Name("OpenSiriMode"), object: nil)
            return true
        }
        return false
    }
}