#if os(iOS) || os(tvOS)
import UIKit

extension UIViewController {
    
    // MARK: - 为什么要用 NSSelector 取 UIApplication 呢
  private class var sharedApplication: UIApplication? {
    let selector = NSSelectorFromString("sharedApplication")
    return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
  }

    
    /// 返回当前应用的最上层 ViewController
  open class var topMost: UIViewController? {
    // 取 application 的 windows
    guard let currentWindows = self.sharedApplication?.windows else { return nil }
    
    var rootViewController: UIViewController?
    // 遍历 application 的 windows
    for window in currentWindows {
        // 按遍历顺序找到第一个拥有 rootViewController 的 window
      if let windowRootViewController = window.rootViewController {
        rootViewController = windowRootViewController
        break
      }
    }

    return self.topMost(of: rootViewController)
  }

  /// 使用递归来逐层遍历给定 ViewController 的各种情况
  open class func topMost(of viewController: UIViewController?) -> UIViewController? {
    // 如果这个 controller Present 了一个另外的 controller
    if let presentedViewController = viewController?.presentedViewController {
      return self.topMost(of: presentedViewController)
    }

    // 如果这个 controller 是 UITabBarController
    if let tabBarController = viewController as? UITabBarController,
      let selectedViewController = tabBarController.selectedViewController {
      return self.topMost(of: selectedViewController)
    }

    // 如果这个 controller 是 UINavigationController
    if let navigationController = viewController as? UINavigationController,
      let visibleViewController = navigationController.visibleViewController {
      return self.topMost(of: visibleViewController)
    }

    // 如果这个 controller 是 UIPageController
    if let pageViewController = viewController as? UIPageViewController,
      pageViewController.viewControllers?.count == 1 {
      return self.topMost(of: pageViewController.viewControllers?.first)
    }

    // 如果以上情况都不是，则再遍历 viewController.view 的 subviews，看是否有子控制器
    for subview in viewController?.view?.subviews ?? [] {
      if let childViewController = subview.next as? UIViewController {
        return self.topMost(of: childViewController)
      }
    }

    return viewController
  }
}
#endif
