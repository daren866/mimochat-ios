import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("AppDelegate didFinishLaunchingWithOptions")
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("AppDelegate open url: \(url)")
        return handleURL(url)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print("AppDelegate open url (legacy): \(url)")
        return handleURL(url)
    }
    
    private func handleURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "gdmimo" else {
            print("Invalid scheme: \(url.scheme ?? "nil")")
            return false
        }
        
        guard url.host?.lowercased() == "siri" else {
            print("Invalid host: \(url.host ?? "nil")")
            return false
        }
        
        print("Opening Siri mode...")
        
        DispatchQueue.main.async {
            let siriVC = SiriViewController()
            siriVC.modalPresentationStyle = .overFullScreen
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                if let rootVC = window.rootViewController {
                    let topVC = rootVC.topMostViewController()
                    topVC.present(siriVC, animated: true, completion: {
                        print("SiriViewController presented successfully")
                    })
                } else {
                    print("No rootViewController found")
                    window.rootViewController = siriVC
                }
            } else {
                print("No window scene found")
                let window = UIWindow()
                window.rootViewController = siriVC
                window.makeKeyAndVisible()
            }
        }
        
        return true
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? self
        }
        if let tabBar = self as? UITabBarController {
            return tabBar.selectedViewController?.topMostViewController() ?? self
        }
        return self
    }
}
