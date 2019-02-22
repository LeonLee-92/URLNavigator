#if os(iOS) || os(tvOS)
import UIKit

#if !COCOAPODS
import URLMatcher
#endif

open class Navigator: NavigatorType {
  public let matcher = URLMatcher()
  open weak var delegate: NavigatorDelegate?

  private var viewControllerFactories = [URLPattern: ViewControllerFactory]()
  private var handlerFactories = [URLPattern: URLOpenHandlerFactory]()

  public init() {
    // ⛵ I'm a Navigator!
  }

    /// 注册路由，传入 模板 和 controller初始化闭包，装入 viewControllerFactories 字典
  open func register(_ pattern: URLPattern, _ factory: @escaping ViewControllerFactory) {
    self.viewControllerFactories[pattern] = factory
  }
    /// 注册事件，传入 模板 和 Event闭包，装入 handlerFactories 字典
  open func handle(_ pattern: URLPattern, _ factory: @escaping URLOpenHandlerFactory) {
    self.handlerFactories[pattern] = factory
  }

    /// 通过传入的 URL 匹配 ViewControllerFactory，并执行 ViewControllerFactoryd 得到返回值 UIViewController
  open func viewController(for url: URLConvertible, context: Any? = nil) -> UIViewController? {
    // 所有注册的 URLPattern
    let urlPatterns = Array(self.viewControllerFactories.keys)
    // 匹配所有注册过的的 URLPattern，并得到匹配结果 URLMatchResult
    guard let match = self.matcher.match(url, from: urlPatterns) else { return nil }
    // 取出 URLMatchResult.pattern 对应的 ViewControllerFactory
    guard let factory = self.viewControllerFactories[match.pattern] else { return nil }
    // 使用传入的参数执行 ViewControllerFactory，创建一个指定的 ViewController
    return factory(url, match.values, context)
  }

    /// 逻辑同上，通过传入的 URL 匹配 URLOpenHandlerFactory，并执行 URLOpenHandlerFactory
  open func handler(for url: URLConvertible, context: Any?) -> URLOpenHandler? {
    let urlPatterns = Array(self.handlerFactories.keys)
    guard let match = self.matcher.match(url, from: urlPatterns) else { return nil }
    guard let handler = self.handlerFactories[match.pattern] else { return nil }
    return { handler(url, match.values, context) }
  }
}
#endif
