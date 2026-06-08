import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "gdmimo" && url.host == "siri" {
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let siriVC = SiriViewController()
                    siriVC.modalPresentationStyle = .overFullScreen
                    if let topVC = window.rootViewController?.topMostViewController() {
                        topVC.present(siriVC, animated: true)
                    } else {
                        window.rootViewController = UINavigationController(rootViewController: siriVC)
                    }
                }
            }
            return true
        }
        return false
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        return self
    }
}
