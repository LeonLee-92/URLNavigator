#if os(iOS) || os(tvOS)
import UIKit

#if !COCOAPODS
import URLMatcher
#endif

public typealias URLPattern = String
public typealias ViewControllerFactory = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> UIViewController?
public typealias URLOpenHandlerFactory = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Bool
public typealias URLOpenHandler = () -> Bool

public protocol NavigatorType {
  var matcher: URLMatcher { get }
  var delegate: NavigatorDelegate? { get set }

    
    
//MARK:-------------------------------  遵从协议者需实现  -------------------------------
    /// 遵从协议者需实现,用 URLPattern 注册一个 ViewControllerFactory (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> UIViewController?
  func register(_ pattern: URLPattern, _ factory: @escaping ViewControllerFactory)

    /// Registers an URL open handler to the URL pattern.
  func handle(_ pattern: URLPattern, _ factory: @escaping URLOpenHandlerFactory)

  /// 遵从协议者需实现,根据指定的 URL，返回匹配的 ViewController, 未能匹配返回 nil
  func viewController(for url: URLConvertible, context: Any?) -> UIViewController?

  /// 遵从协议者需实现,根据指定的 URL，返回匹配的 URLOpenHandler（ () -> Bool 闭包 ）, 未能匹配返回 nil
  func handler(for url: URLConvertible, context: Any?) -> URLOpenHandler?

    
//MARK:-------------------------------  协议下方自行扩展  -------------------------------
    /// Push 一个被匹配到的 ViewController 到 NavigationController 的栈
    /// 此函数优缺点，它要求所有参数 ？？？
    /// 此函数会在使用 URL 去 push 一个 ViewController 的时候被调用
    /// 建议此函数只用作 mock
  @discardableResult
  func pushURL(_ url: URLConvertible, context: Any?, from: UINavigationControllerType?, animated: Bool) -> UIViewController?

    /// Push 一个被匹配到的 ViewController 到 NavigationController 的栈
    /// 此函数优缺点，它要求所有参数 ？？？
    /// 此函数会在 push 一个 ViewController 的时候被调用
    /// 建议此函数只用作 mock
  @discardableResult
  func pushViewController(_ viewController: UIViewController, from: UINavigationControllerType?, animated: Bool) -> UIViewController?

    /// Present 一个被匹配到的 ViewController
    /// 此函数优缺点，它要求所有参数 ？？？
    /// 此函数会在使用 URL 去 Present 一个 ViewController 的时候被调用
    /// 建议此函数只用作 mock
  @discardableResult
  func presentURL(_ url: URLConvertible, context: Any?, wrap: UINavigationController.Type?, from: UIViewControllerType?, animated: Bool, completion: (() -> Void)?) -> UIViewController?

    /// Present 一个被匹配到的 ViewController
    /// 此函数优缺点，它要求所有参数 ？？？
    /// 此函数会在 Present 一个 ViewController 的时候被调用
    /// 建议此函数只用作 mock
  @discardableResult
  func presentViewController(_ viewController: UIViewController, wrap: UINavigationController.Type?, from: UIViewControllerType?, animated: Bool, completion: (() -> Void)?) -> UIViewController?

    //MARK: - ????????
  /// Executes an URL open handler.
  ///
  /// - note: It is not a good idea to use this method directly because this method requires all
  ///         parameters. This method eventually gets called when opening an url, so it's
  ///         recommended to implement this method only for mocking.
  @discardableResult
  func openURL(_ url: URLConvertible, context: Any?) -> Bool
}


// MARK: - Protocol 的必要方法
extension NavigatorType {
    
    /// 根据指定的 URL，返回匹配的 UIViewController, 未能匹配返回 nil
  public func viewController(for url: URLConvertible) -> UIViewController? {
    
    /// 此函数需遵从协议者实现
    return self.viewController(for: url, context: nil)
  }
    
    /// 根据指定的 URL，返回匹配的 URLOpenHandler（ () -> Bool 闭包 ）, 未能匹配返回 nil
  public func handler(for url: URLConvertible) -> URLOpenHandler? {
    return self.handler(for: url, context: nil)
  }

    
    /// 按指定的 URL 构建 ViewController ，并 push
  @discardableResult
  public func pushURL(_ url: URLConvertible, context: Any? = nil, from: UINavigationControllerType? = nil, animated: Bool = true) -> UIViewController? {
    // 按指定的 URL 构建 ViewController
    guard let viewController = self.viewController(for: url, context: context) else { return nil }
    return self.pushViewController(viewController, from: from, animated: animated)
  }

    /// Push 指定的 ViewController，如果 from 传参为 nil 则自动确定合适的 UINavigationController
  @discardableResult
  public func pushViewController(_ viewController: UIViewController, from: UINavigationControllerType?, animated: Bool) -> UIViewController? {
    guard (viewController is UINavigationController) == false else { return nil }
    guard let navigationController = from ?? UIViewController.topMost?.navigationController else { return nil }
    guard self.delegate?.shouldPush(viewController: viewController, from: navigationController) != false else { return nil }
    navigationController.pushViewController(viewController, animated: animated)
    return viewController
  }

    
    /// 按指定的 URL 构建 ViewController ，并 present
  @discardableResult
  public func presentURL(_ url: URLConvertible, context: Any? = nil, wrap: UINavigationController.Type? = nil, from: UIViewControllerType? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
    guard let viewController = self.viewController(for: url, context: context) else { return nil }
    return self.presentViewController(viewController, wrap: wrap, from: from, animated: animated, completion: completion)
  }

    /// Present 指定的 ViewController，wrap 为需要的导航控制器类型，如果 from 传参为 nil 则自动确定合适的 ViewController
  @discardableResult
  public func presentViewController(_ viewController: UIViewController, wrap: UINavigationController.Type?, from: UIViewControllerType?, animated: Bool, completion: (() -> Void)?) -> UIViewController? {
    guard let fromViewController = from ?? UIViewController.topMost else { return nil }

    let viewControllerToPresent: UIViewController
    if let navigationControllerClass = wrap, (viewController is UINavigationController) == false {
      viewControllerToPresent = navigationControllerClass.init(rootViewController: viewController)
    } else {
      viewControllerToPresent = viewController
    }

    guard self.delegate?.shouldPresent(viewController: viewController, from: fromViewController) != false else { return nil }
    fromViewController.present(viewControllerToPresent, animated: animated, completion: completion)
    return viewController
  }

    /// 按指定的 URL 构建 Event 闭包 ，并执行
  @discardableResult
  public func openURL(_ url: URLConvertible, context: Any?) -> Bool {
    guard let handler = self.handler(for: url, context: context) else { return false }
    return handler()
  }
}


// MARK: - 封装语法糖
// 仅为函数封装了传参的默认值

extension NavigatorType {
  @discardableResult
  public func push(_ url: URLConvertible, context: Any? = nil, from: UINavigationControllerType? = nil, animated: Bool = true) -> UIViewController? {
    return self.pushURL(url, context: context, from: from, animated: animated)
  }

  @discardableResult
  public func push(_ viewController: UIViewController, from: UINavigationControllerType? = nil, animated: Bool = true) -> UIViewController? {
    return self.pushViewController(viewController, from: from, animated: animated)
  }

  @discardableResult
  public func present(_ url: URLConvertible, context: Any? = nil, wrap: UINavigationController.Type? = nil, from: UIViewControllerType? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
    return self.presentURL(url, context: context, wrap: wrap, from: from, animated: animated, completion: completion)
  }

  @discardableResult
  public func present(_ viewController: UIViewController, wrap: UINavigationController.Type? = nil, from: UIViewControllerType? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
    return self.presentViewController(viewController, wrap: wrap, from: from, animated: animated, completion: completion)
  }

  @discardableResult
  public func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
    return self.openURL(url, context: context)
  }
}
#endif
