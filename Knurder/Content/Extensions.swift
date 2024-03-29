//
//  Extensions.swift
//  FirstDb
//
//  Created by Dale Seng on 5/15/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation
import UIKit

private let characterEntities : [ Substring : Character ] = [
  // XML predefined entities:
  "&quot;"    : "\"",
  "&amp;"     : "&",
  "&apos;"    : "'",
  "&lt;"      : "<",
  "&gt;"      : ">",
  
  // HTML character entity references:
  "&nbsp;"    : "\u{00a0}",
  // ...
  "&diams;"   : "?",
]

public extension StringProtocol {
  func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
      range(of: string, options: options)?.lowerBound
  }
  func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
      range(of: string, options: options)?.upperBound
  }
  func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
      ranges(of: string, options: options).map(\.lowerBound)
  }
  func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
      var result: [Range<Index>] = []
      var startIndex = self.startIndex
      while startIndex < endIndex,
          let range = self[startIndex...]
              .range(of: string, options: options) {
              result.append(range)
              startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                  index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
      }
      return result
  }
}


public extension String {
  
  var underLined: NSAttributedString {
    NSMutableAttributedString(string: self, attributes: [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue])
  }
  
  func deletePrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else {return self}
    return String(self.dropFirst(prefix.count))
  }
  
  func wrapInQuotes(_ unquoted: String) -> String {
    let searchFor = ":\(unquoted),"
    let quoted = ":\"\(unquoted)\","
    
    return String(self.replacingOccurrences(of: searchFor, with: quoted))
  }
  
  func wrapStars() -> String {
    //print("output: " + String(locationInString("\"stars\":[\\d]")))
    return String(wrapValueInQuotes("\"stars\":[\\d]"))
  }
  
  func wrapValueInQuotes(_ regex: String) -> String {
    var resultString: String = self
    
    if let locRegEx = try? NSRegularExpression(pattern: regex, options: .caseInsensitive) {
      let selfString = self as NSString
      let matches = locRegEx.matches(in: self, options: [], range: NSRange(location: 0, length: selfString.length))
      
      for match in matches {
        //let range = match.range
        let matchString = selfString.substring(with: match.range) as String
        let components = matchString.components(separatedBy: ":")
        let replaceString = components[0] + ":\"" + components[1] + "\""
        //print("match is \(range) \(matchString)")
        //print("range: \(range.lowerBound)")
        resultString = selfString.replacingOccurrences(of: matchString, with: replaceString)
        break // only do first one
      }
    }
    return resultString
  }
  
  
  func removeFirstAndLast() -> String {
    let noFirstAndLastRange = self.index(after: self.startIndex)..<self.index(before: self.endIndex)
    return String(self[noFirstAndLastRange])
  }
  
  func removeLast() -> String {
    //let noLastRange: Range = self.startIndex..<self.index(before: self.endIndex)
    let noLastRange: Range = self.startIndex..<self.index(before: self.endIndex)
    return String(self[noLastRange])
  }
  
  
  func trim() -> String {
    return self.trimmingCharacters(in: CharacterSet.whitespaces)
  }
  
  func clean() -> String {
    var _key = self.trimmingCharacters(in: CharacterSet.whitespaces)

    while let uniRange = _key[_key.startIndex...].range(of: "\\u") {
      let charDefRange = uniRange.upperBound..<_key.index(uniRange.upperBound, offsetBy: 4)
      let uniFullRange = uniRange.lowerBound..<charDefRange.upperBound
      let charDef = "&#x" + _key[charDefRange] + ";"
      _key = _key.replacingCharacters(in: uniFullRange, with: charDef)
    }
    _key = _key.stringByDecodingHTMLEntities
    
    let hasPrefix = _key.hasPrefix("<p>")
    //print("\(hasPrefix) _key: \(_key)")
    _key = _key.replacingOccurrences(of: "\\/", with: "/")
    _key = _key.replacingOccurrences(of: "<br/>", with: "")
    _key = _key.replacingOccurrences(of: "<br />", with: "")
    _key = _key.replacingOccurrences(of: "\\r\\n", with: "")
    _key = _key.replacingOccurrences(of: "<p>", with: "")
    _key = _key.replacingOccurrences(of: "</p>", with: "")
    _key = _key.replacingOccurrences(of: "<P>", with: "")
    _key = _key.replacingOccurrences(of: "</P>", with: "")
    _key = _key.replacingOccurrences(of: "\\r\\n", with: "")
    
    return _key
  }
  
  func getMatchArea(match: String, leftOffset: Int, rightOffset: Int) -> String {
    let desc = self.uppercased()
    guard let toIndex = desc.range(of: match)?.upperBound else {
      return ""
    }
    let offsets: [Int] = [toIndex.encodedOffset, leftOffset]
    let minOffset: Int = offsets.min()!
    let minOffset2: Int = minOffset - match.count
    let fromIndex = desc.index((desc.range(of: match)?.lowerBound)!, offsetBy: -minOffset2)
    return String(desc[fromIndex..<toIndex])
  }
  
  func getNumberStringFromString() -> String {
    let words = self.components(separatedBy: " ")
    var anAbvNumber = "0"
    for i in (1...words.count).reversed() {
      let aCandidate = words[i-1].replacingOccurrences(of: "[^\\d.]", with: "", options: .regularExpression)
      if (!aCandidate.isEmpty && !aCandidate.hasPrefix(".")) {
        anAbvNumber = aCandidate
        break;
      }
    }
    return anAbvNumber
  }

  func indexOf(_ substring: String, _ offset: Int ) -> Int {
        //print("Extension.swift indexOf(substring, offset)")
        if(offset > count) {return -1}

        let maxIndex = self.count - substring.count
        if(maxIndex >= 0) {
            for index in offset...maxIndex {
                let rangeSubstring = self.index(self.startIndex, offsetBy: index)..<self.index(self.startIndex, offsetBy: index + substring.count)
                #if swift(>=4)
                let selfSubstring = self[rangeSubstring]
                #else
                let selfSubstring = self.substring(with: rangeSubstring)
                #endif
                if selfSubstring == substring {
                    //print("Extension.swift indexOf(" + substring + "," + String(offset) + ") returning " + String(index))
                    return index
                }
            }
        }
        //print("Extension.swift indexOf(" + substring + "," + String(offset) + ") returning -1")
        return -1
    }

  func indexOf(_ substring: String) -> Int {
        return self.indexOf(substring, 0)
    }

  func replaceAll(of pattern: String, with replacement: String, options: NSRegularExpression.Options = []) -> String {
      do {
          let regex = try NSRegularExpression(pattern: pattern, options: [])
          let range = NSRange(0..<self.utf16.count)
          return regex.stringByReplacingMatches(in: self, options: [],
                                                range: range, withTemplate: replacement)
      } catch {
          return self
      }
  }
  
  mutating func replaceAllAlt(_ originalString:String, with newString:String) {
    self = self.replacingOccurrences(of: originalString, with: newString)
  }
  
  func deAccent() -> String {
    return self.folding(options: .diacriticInsensitive, locale: .current)
  }

  func levenshteinDistanceScore(to string: String, ignoreCase: Bool = true, trimWhiteSpacesAndNewLines: Bool = true) -> Float {

      var firstString = self
      var secondString = string

      if ignoreCase {
          firstString = firstString.lowercased()
          secondString = secondString.lowercased()
      }
      if trimWhiteSpacesAndNewLines {
          firstString = firstString.trimmingCharacters(in: .whitespacesAndNewlines)
          secondString = secondString.trimmingCharacters(in: .whitespacesAndNewlines)
      }

      let empty = [Int](repeating:0, count: secondString.count)
      var last = [Int](0...secondString.count)

      for (i, tLett) in firstString.enumerated() {
          var cur = [i + 1] + empty
          for (j, sLett) in secondString.enumerated() {
              cur[j + 1] = tLett == sLett ? last[j] : Swift.min(last[j], last[j + 1], cur[j])+1
          }
          last = cur
      }

      // maximum string length between the two
      let lowestScore = max(firstString.count, secondString.count)

      if let validDistance = last.last {
          return  1 - (Float(validDistance) / Float(lowestScore))
      }

      return 0.0
  }
  
  /*************IMPORTED**************/
  /// Returns a new string made by replacing in the `String`
  /// all HTML character entity references with the corresponding
  /// character.
  var stringByDecodingHTMLEntities : String {
    
    // ===== Utility functions =====
    
    // Convert the number in the string to the corresponding
    // Unicode character, e.g.
    //    decodeNumeric("64", 10)   --> "@"
    //    decodeNumeric("20ac", 16) --> "Ä"
    func decodeNumeric(_ string : Substring, base : Int) -> Character? {
      guard let code = UInt32(string, radix: base),
        let uniScalar = UnicodeScalar(code) else { return nil }
      return Character(uniScalar)
    }
    
    // Decode the HTML character entity to the corresponding
    // Unicode character, return `nil` for invalid input.
    //     decode("&#64;")    --> "@"
    //     decode("&#x20ac;") --> "Ä"
    //     decode("&lt;")     --> "<"
    //     decode("&foo;")    --> nil
    func decode(_ entity : Substring) -> Character? {
      
      if entity.hasPrefix("&#x") || entity.hasPrefix("&#X") {
        return decodeNumeric(entity.dropFirst(3).dropLast(), base: 16)
      } else if entity.hasPrefix("&#") {
        return decodeNumeric(entity.dropFirst(2).dropLast(), base: 10)
      } else {
        return characterEntities[entity]
      }
    }
    
    // ===== Method starts here =====
    
    var result = ""
    var position = startIndex
    
    // Find the next '&' and copy the characters preceding it to `result`:
    while let ampRange = self[position...].range(of: "&") {
      result.append(contentsOf: self[position ..< ampRange.lowerBound])
      position = ampRange.lowerBound
      
      // Find the next ';' and copy everything from '&' to ';' into `entity`
      guard let semiRange = self[position...].range(of: ";") else {
        // No matching ';'.
        break
      }
      let entity = self[position ..< semiRange.upperBound]
      position = semiRange.upperBound
      
      if let decoded = decode(entity) {
        // Replace by decoded character:
        result.append(decoded)
      } else {
        // Invalid entity, copy verbatim:
        result.append(contentsOf: entity)
      }
    }
    // Copy remaining characters to `result`:
    result.append(contentsOf: self[position...])
    return result
  }
  /************END IMPORTED**********/
}

public extension URL {
  
  /**
   Add, update, or remove a query string parameter from the URL
   
   - parameter url:   the URL
   - parameter key:   the key of the query string parameter
   - parameter value: the value to replace the query string parameter, nil will remove item
   
   - returns: the URL with the mutated query string
   */
  func appendingQueryItem(_ name: String, value: Any?) -> String {
    guard var urlComponents = URLComponents(string: absoluteString) else {
      return absoluteString
    }
    
    urlComponents.queryItems = urlComponents.queryItems?
      .filter { $0.name.lowercased() != name.lowercased() } ?? []
    
    // Skip if nil value
    if let value = value {
      urlComponents.queryItems?.append(URLQueryItem(name: name, value: "\(value)"))
    }
    
    return urlComponents.string ?? absoluteString
  }
  
  /**
   Add, update, or remove a query string parameters from the URL
   
   - parameter url:   the URL
   - parameter values: the dictionary of query string parameters to replace
   
   - returns: the URL with the mutated query string
   */
  func appendingQueryItems(_ contentsOf: [String: Any?]) -> String {
    guard var urlComponents = URLComponents(string: absoluteString), !contentsOf.isEmpty else {
      return absoluteString
    }
    
    let keys = contentsOf.keys.map { $0.lowercased() }
    
    urlComponents.queryItems = urlComponents.queryItems?
      .filter { !keys.contains($0.name.lowercased()) } ?? []
    
    urlComponents.queryItems?.append(contentsOf: contentsOf.flatMap {
      guard let value = $0.value else { return nil } //Skip if nil
      return URLQueryItem(name: $0.key, value: "\(value)")
    })
    
    return urlComponents.string ?? absoluteString
  }
  
  /**
   Removes a query string parameter from the URL
   
   - parameter url:   the URL
   - parameter key:   the key of the query string parameter
   
   - returns: the URL with the mutated query string
   */
  func removeQueryItem(_ name: String) -> String {
    return appendingQueryItem(name, value: nil)
  }
  
  func appending(_ queryItem: String, value: String?) -> URL {

      guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }

      // Create array of existing query items
      var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []

      // Create query item
      let queryItem = URLQueryItem(name: queryItem, value: value)

      // Append the new query item in the existing query items array
      queryItems.append(queryItem)

      // Append updated query items array in the url component object
      urlComponents.queryItems = queryItems

      // Returns the url from new url components
      return urlComponents.url!
  }
}



