#if os(iOS) || os(tvOS)
import UIKit

public protocol NavigatorDelegate: class {
    /// 用于屏蔽一些不想 push 或 present 的操作
    /// 代理使用此函数返回是否应该 Push ViewController，默认为 true
  func shouldPush(viewController: UIViewController, from: UINavigationControllerType) -> Bool
    /// 用于屏蔽一些不想 push 或 present 的操作
    /// 代理使用此函数返回是否应该 PresentViewController，默认为 true
  func shouldPresent(viewController: UIViewController, from: UIViewControllerType) -> Bool
}

extension NavigatorDelegate {
  public func shouldPush(viewController: UIViewController, from: UINavigationControllerType) -> Bool {
    return true
  }

  public func shouldPresent(viewController: UIViewController, from: UIViewControllerType) -> Bool {
    return true
  }
}
#endif
