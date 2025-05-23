import Foundation
import os.log
import SwiftSoup

class Parser {
    private static let logger = Logger(subsystem: "com.wheatfox.plovix", category: "parser")
    
    static func parseMsgsFromListPage(from html: String) -> [Message] {
        logger.info("Starting to parse messages from HTML")
        var messages: [Message] = []
        
        return messages
    }

    static func parseListsFromHomePage(from html: String) -> [(name: String, desc: String)] {
        logger.info("Starting to parse mailing lists from HTML")
        var lists: [(name: String, desc: String)] = []
        
        do {
            let doc = try SwiftSoup.parse(html)
            let preElements = try doc.select("pre")
            
            for pre in preElements {
                let content = try pre.text()
                let lines = content.components(separatedBy: .newlines)
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if !trimmedLine.isEmpty {
                        let components = trimmedLine.components(separatedBy: " - ")
                        if components.count >= 2 {
                            var name = components[1]
                            var desc = components[0]
                            name = name.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces)
                            desc = desc.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces)
                            lists.append((name, desc))
                        }
                    }
                }
            }
            lists.sort { $0.name < $1.name }
            
            logger.info("Finished parsing mailing lists. Found \(lists.count) lists")
        } catch {
            logger.error("Error parsing HTML: \(error.localizedDescription)")
        }
        
        return lists
    }

    static func parseMsgsFromListPage(from html: String, listName: String) -> [Message] {
        logger.debug("Parsing messages at list \(listName)")
        var rootMessages: [Message] = []
        var messageMap: [String: Message] = [:]
        var orderedMessages: [Message] = []
        
        do {
            let doc = try SwiftSoup.parse(html)
            let links = try doc.select("a[href$=/T/#t]")
            
            for link in links {
                let url = try link.attr("href")
                let subject = try link.text()
                let parent = try link.parent()?.parent()
                let dateText = try parent?.text() ?? ""
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                
                let message = Message(
                    subject: subject,
                    content: url,
                    timestamp: dateFormatter.date(from: dateText) ?? Date()
                )
                
                let messageId = url.split(separator: "/").first.map(String.init) ?? ""
                messageMap[messageId] = message
                orderedMessages.append(message)
                
                let parentText = try parent?.text() ?? ""
                if parentText.prefix(10).contains("`") {
                    if let parentId = parentText.split(separator: "/").first.map(String.init),
                       let parentMessage = messageMap[parentId] {
                        message.parent = parentMessage
                        parentMessage.replies.append(message)
                    }
                } else {
                    rootMessages.append(message)
                }
            }
            
            // 保持原始顺序
            rootMessages.sort { m1, m2 in
                guard let idx1 = orderedMessages.firstIndex(of: m1),
                      let idx2 = orderedMessages.firstIndex(of: m2) else {
                    return false
                }
                return idx1 < idx2
            }
            
            // 对每个消息的回复也保持原始顺序
            for message in rootMessages {
                message.replies.sort { m1, m2 in
                    guard let idx1 = orderedMessages.firstIndex(of: m1),
                          let idx2 = orderedMessages.firstIndex(of: m2) else {
                        return false
                    }
                    return idx1 < idx2
                }
            }
        } catch {
            logger.error("Error parsing HTML: \(error.localizedDescription)")
        }
        
        logger.debug("Parsed \(rootMessages.count) root messages for list \(listName)")
        return rootMessages
    }
} 