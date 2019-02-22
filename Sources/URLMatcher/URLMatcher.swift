import Foundation

/// URLMatcher provides a way to match URLs against a list of specified patterns.
///
/// URLMatcher extracts the pattern and the values from the URL if possible.

// URLMatcher 用于提供 【提取 URL 中的格式和参数】的方法
open class URLMatcher {
    
    /// 使类型更有语义
  public typealias URLPattern = String
    /// 定义闭包类型，以第二个参数为索引，返回第一个数组参数的元素，并返回特定类型
  public typealias URLValueConverter = (_ pathComponents: [String], _ index: Int) -> Any?
  static let defaultURLValueConverters: [String: URLValueConverter] = [
    "string": { pathComponents, index in
      return pathComponents[index]
    },
    "int": { pathComponents, index in
      return Int(pathComponents[index])
    },
    "float": { pathComponents, index in
      return Float(pathComponents[index])
    },
    "uuid": { pathComponents, index in
      return UUID(uuidString: pathComponents[index])
    },
    "path": { pathComponents, index in
      return pathComponents[index..<pathComponents.count].joined(separator: "/")
    }
  ]
    /// 只是用上面的常量赋值给了变量，感觉是多余的代码
  open var valueConverters: [String: URLValueConverter] = URLMatcher.defaultURLValueConverters

  public init() {
    /// 🔄 I'm an URLMatcher!
  }

    /// 从指定URL中,按指定的key返回参数列表（ URLMatchResult类型 ）, 匹配不到则返回 nil
    /// For example:
    ///     let result = matcher.match("myapp://user/123", from: ["myapp://user/<int:id>"])
    ///
  open func match(_ url: URLConvertible, from candidates: [URLPattern]) -> URLMatchResult? {
    /// 去除后缀，移除非法字符
    let url = self.normalizeURL(url)
    /// "app://abc.com/abc?a=1&b=2" -> "app"
    let scheme = url.urlValue?.scheme
    // "app://abc.com/abc/a=1&b=2" -> ["abc.com","abc","a=1&b=2"]
    let stringPathComponents = self.stringPathComponents(from :url)

    for candidate in candidates {
        // 协议头不相同不匹配
      guard scheme == candidate.urlValue?.scheme else { continue }
        // URLPattern 命中则直接返回，所以前面的 URLPattern 优先级高
      if let result = self.match(stringPathComponents, with: candidate) {
        return result
      }
    }

    return nil
  }

  func match(_ stringPathComponents: [String], with candidate: URLPattern) -> URLMatchResult? {
    // URLPattern 去除后缀，移除非法字符，e.g."myapp://user.com/abc/<int:id>"
    let normalizedCandidate = self.normalizeURL(candidate).urlStringValue
    // -> [.plain("user.com"), .plain("abc"), .placeholder(type: "int", key:"id")]
    let candidatePathComponents = self.pathComponents(from: normalizedCandidate)
    // 匹配 【原url字符串路径 与 占位符】个数相等，或者占位符中有指定的 path 类型
    guard self.ensurePathComponentsCount(stringPathComponents, candidatePathComponents) else {
      return nil
    }
    // 存放
    var urlValues: [String: Any] = [:]
    // min(路径数组的个数，匹配项个数)
    let pairCount = min(stringPathComponents.count, candidatePathComponents.count)
    
    for index in 0..<pairCount {
        // 将 (URLStringComponent， 规则) 转换为 URLPathComponentMatchResult
      let result = self.matchStringPathComponent(
        at: index,
        from: stringPathComponents,
        with: candidatePathComponents
      )
        
      switch result {
        // 如果 .matches(key, value) 中 key和value 都有值的话
        // 以 key：value 的形式存储
      case let .matches(placeholderValue):
        if let (key, value) = placeholderValue {
          urlValues[key] = value
        }
        
      //异常处理，直接返回 nil
      case .notMatches:
        return nil
      }
    }
    
    // 包装 【匹配规则字符串】 和 【参数key:value】 为 URLMatchResult 类型
    return URLMatchResult(pattern: candidate, values: urlValues)
  }
    /// 去除后缀，移除非法字符 (normalize:使正常化；使规格化，使标准化)
  func normalizeURL(_ dirtyURL: URLConvertible) -> URLConvertible {
    /// 非空处理
    guard dirtyURL.urlValue != nil else { return dirtyURL }
    /// URL -> String
    var urlString = dirtyURL.urlStringValue
    ///      "myapp://user/abc#position?key=value"
    ///  ->  "myapp://user/abc#position"
    ///  ->  "myapp://user/abc"
    urlString = urlString.components(separatedBy: "?")[0].components(separatedBy: "#")[0]
    /// "myapp://///user/abc" -> "myapp://user/abc"
    urlString = self.replaceRegex(":/{3,}", "://", urlString)
    /// 具体看不懂，替换非法字符
    urlString = self.replaceRegex("(?<!:)/{2,}", "/", urlString)
    urlString = self.replaceRegex("(?<!:|:/)/+$", "", urlString)
    return urlString
  }

  func replaceRegex(_ pattern: String, _ repl: String, _ string: String) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return string }
    let range = NSMakeRange(0, string.count)
    return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: repl)
  }

    /// 匹配 【原url字符串路径 与 占位符】个数
  func ensurePathComponentsCount(
    _ stringPathComponents: [String],
    _ candidatePathComponents: [URLPathComponent]
  ) -> Bool {
    // 原url字符串路径 与 占位符 个数相等
    let hasSameNumberOfComponents = (stringPathComponents.count == candidatePathComponents.count)
    // 或者占位符中有指定 path 类型
    let containsPathPlaceholderComponent = candidatePathComponents.contains {
      if case let .placeholder(type, _) = $0, type == "path" {
        return true
      } else {
        return false
      }
    }
    return hasSameNumberOfComponents || containsPathPlaceholderComponent
  }

    /// "app://abc.com/abc?a=1&b=2" -> ["app:","","abc.com","abc?a=1&b=2"] -> ["abc.com","abc?a=1&b=2"]
    /// 按 / 分割，去除【以 : 结尾的字符串】和【""】
  func stringPathComponents(from url: URLConvertible) -> [String] {
    /// 关于集合使用 .lazy 的官方解释：1.避免内存开销 2.你可能只需要集合中的一部分数据
    /// A view onto this collection that provides lazy implementations of
    /// normally eager operations, such as `map` and `filter`.
    ///
    /// Use the `lazy` property when chaining operations to prevent
    /// intermediate operations from allocating storage, or when you only
    /// need a part of the final collection to avoid unnecessary computation.
    
    /// "app://abc.com/abc?a=1&b=2" -> ["app:","","abc.com","abc?a=1&b=2"] -> ["abc.com","abc?a=1&b=2"]
    return url.urlStringValue.components(separatedBy: "/").lazy
      .filter { !$0.isEmpty }
      .filter { !$0.hasSuffix(":") }
  }
    
    /// 将 URLPattern 转换为 匹配规则数组[URLPathComponent]
    /// "myapp://user.com/abc/<int:id>" -> ["user.com","abc","<int:id>"] -> [.plain("user.com"), .plain("abc"), .placeholder(type: "int", key:"id")]
  func pathComponents(from url: URLPattern) -> [URLPathComponent] {
    // "myapp://user.com/abc/<int:id>" -> ["user.com","abc","<int:id>"] -> [.plain("user.com"), .plain("abc"), .placeholder(type: "int", key:"id")]
    return self.stringPathComponents(from: url).map(URLPathComponent.init)
  }

    /// 将某一对 URLcomponent和匹配规则 转换为 URLPathComponentMatchResult
    ///
    ///
  func matchStringPathComponent(
    at index: Int,
    from stringPathComponents: [String],
    with candidatePathComponents: [URLPathComponent]
  ) -> URLPathComponentMatchResult {
    // URLString 的某一个 component
    let stringPathComponent = stringPathComponents[index]
    // 某一个匹配规则
    let urlPathComponent = candidatePathComponents[index]

    
    switch urlPathComponent {
        // .plain(value)类型其实不是匹配规则的一部分，是 URLPattern 匹配规则前面的某一个 URLComponent
    case let .plain(value):
        // 和 URLString 的 Component 一致，则返回 .matches(nil)
      guard stringPathComponent == value else { return .notMatches }
      return .matches(nil)

        // .placeholder(type, key)类型的是用户定义的匹配规则，e.g."<int:id>" -> .placeholder(type: "int", key:"id")
    case let .placeholder(type, key):
        // 保证 type 不为 nil，并且有定义好与之对应的 URLValueConverter
      guard let type = type, let converter = self.valueConverters[type] else {
        // type == nil 则是这种无类型的情况: "<title>" -> .placeholder(type: nil, key: "title")
        // "abc.com/我是title", "abc.com/<title>" -> .matches(("title", "我是title"))
        return .matches((key, stringPathComponent))
      }
      // 使用对应的 URLValueConverter 转换 URLString 中的传参
      if let value = converter(stringPathComponents, index) {
        return .matches((key, value))
      } else {
        return .notMatches
      }
    }
  }
}
