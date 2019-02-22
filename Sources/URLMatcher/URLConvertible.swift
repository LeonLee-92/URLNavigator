import Foundation

/// A type which can be converted to an URL string.

// 定义协议，后续为 URL, String 扩展了 urlValue, urlStringValue 计算属性
// 功能： String 与 URL 互转， 匹配url中的参数列表
public protocol URLConvertible {
  var urlValue: URL? { get }
  var urlStringValue: String { get }

    /// 返回 URL 的参数列表。为了方便，即便没有匹配的 key 也不会返回 nil
    /// 本属性不关心重复的 key，如果需要请使用 queryItems 属性
  var queryParameters: [String: String] { get }

    /// 同上
  @available(iOS 8, *)
  var queryItems: [URLQueryItem]? { get }
}

extension URLConvertible {
    
    // 返回 URL 或 String 中的参数列表
  public var queryParameters: [String: String] {
    var parameters = [String: String]()
    // "app://abc.def?a=b&c=d" -> "a=b&c=d" -> ["a=b", "c=d"].forEach
    self.urlValue?.query?.components(separatedBy: "&").forEach { component in
        // 无 "=" 符号，丢弃
      guard let separatorIndex = component.index(of: "=") else { return }
        // key 的 range
      let keyRange = component.startIndex..<separatorIndex
        // value 的 range
      let valueRange = component.index(after: separatorIndex)..<component.endIndex
        
      let key = String(component[keyRange])
        // 学到了，判断是否包含中文，removingPercentEncoding: UTF8 -> GB2312String
      let value = component[valueRange].removingPercentEncoding ?? String(component[valueRange])
      parameters[key] = value
    }
    return parameters
  }

    // 同上
  @available(iOS 8, *)
  public var queryItems: [URLQueryItem]? {
    // TODO: - 试了下，这个处理中文还是有问题的
    return URLComponents(string: self.urlStringValue)?.queryItems
  }
}

extension String: URLConvertible {
    // 满足 URLConvertible 协议
  public var urlValue: URL? {
    // 能转直接转
    if let url = URL(string: self) {
      return url
    }
    // 设定字符集转换中文之类的东西
    var set = CharacterSet()
    set.formUnion(.urlHostAllowed)
    set.formUnion(.urlPathAllowed)
    set.formUnion(.urlQueryAllowed)
    set.formUnion(.urlFragmentAllowed)
    return self.addingPercentEncoding(withAllowedCharacters: set).flatMap { URL(string: $0) }
  }
    // 满足 URLConvertible 协议
  public var urlStringValue: String {
    return self
  }
}

extension URL: URLConvertible {
    // 满足 URLConvertible 协议
  public var urlValue: URL? {
    return self
  }
    // 满足 URLConvertible 协议
  public var urlStringValue: String {
    return self.absoluteString
  }
}

