import Foundation

public struct Message: Sendable {
    public let root: Part
    public let htmlBody: String?
    public let plainBody: String?
    public let attachments: [Part]
    public let inlineParts: [Part]
    private let contentIDIndex: [String: Part]

    public init(data: Data) {
        let root = MSG.isMSG(data) ? (MSG.parse(data) ?? MIME.parse(data)) : MIME.parse(data)
        self.root = root
        self.htmlBody = Self.findBody(root, contentType: "text/html")?.decodedText()
        self.plainBody = Self.findBody(root, contentType: "text/plain")?.decodedText()
        var attachments: [Part] = []
        var inlineParts: [Part] = []
        var contentIDIndex: [String: Part] = [:]
        Self.collectAttachments(root, into: &attachments)
        Self.collectInlines(root, into: &inlineParts)
        Self.walk(root) { part in
            if let id = part.contentID, contentIDIndex[id] == nil { contentIDIndex[id] = part }
        }
        self.attachments = attachments
        self.inlineParts = inlineParts
        self.contentIDIndex = contentIDIndex
    }

    public init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self.init(data: data)
    }

    public var headers: [(String, String)] { root.rawHeaders }

    public var from: String { decodedHeader("From") }
    public var to: String { decodedHeader("To") }
    public var cc: String { decodedHeader("Cc") }
    public var bcc: String { decodedHeader("Bcc") }
    public var subject: String { decodedHeader("Subject") }
    public var date: String { decodedHeader("Date") }
    public var replyTo: String { decodedHeader("Reply-To") }

    public func decodedHeader(_ name: String) -> String {
        guard let raw = root.header(name) else { return "" }
        let decoded = Decoding.decodeEncodedWords(raw)
        guard ["from", "to", "cc", "bcc", "reply-to"].contains(name.lowercased()) else { return decoded }
        return Self.unquoteNames(decoded)
    }

    private static func unquoteNames(_ header: String) -> String {
        let chars = Array(header)
        var output = ""
        var index = 0
        var atStart = true
        while index < chars.count {
            let char = chars[index]
            if atStart && char == "\"" {
                var end = index + 1
                var name = ""
                while end < chars.count && chars[end] != "\"" {
                    if chars[end] == "\\", end + 1 < chars.count,
                       chars[end + 1] == "\\" || chars[end + 1] == "\"" {
                        end += 1
                    }
                    name.append(chars[end])
                    end += 1
                }
                var next = end + 1
                while next < chars.count && chars[next].isWhitespace { next += 1 }
                if end < chars.count && next < chars.count && chars[next] == "<" {
                    output += name
                    index = end + 1
                    atStart = false
                    continue
                }
            }
            output.append(char)
            if char == "," { atStart = true } else if !char.isWhitespace { atStart = false }
            index += 1
        }
        return output
    }

    // MARK: - Bodies

    public func findBodyPart(contentType: String) -> Part? {
        Self.findBody(root, contentType: contentType)
    }

    private static func findBody(_ part: Part, contentType: String) -> Part? {
        if !part.isMultipart,
           part.contentType == contentType,
           part.disposition?.lowercased() != "attachment" {
            return part
        }
        for sub in part.parts {
            if let f = findBody(sub, contentType: contentType) { return f }
        }
        return nil
    }

    // MARK: - Attachments / inlines

    private static func collectAttachments(_ part: Part, into: inout [Part]) {
        if !part.isMultipart {
            let disp = part.disposition?.lowercased()
            let isExplicitAttachment = disp == "attachment"
            let isBodyText = (part.contentType == "text/plain" || part.contentType == "text/html") &&
                             disp != "attachment"
            let hasName = part.filename != nil
            if isExplicitAttachment || (!isBodyText && hasName && disp != "inline") {
                into.append(part)
            }
        }
        for sub in part.parts { collectAttachments(sub, into: &into) }
    }

    private static func collectInlines(_ part: Part, into: inout [Part]) {
        if !part.isMultipart, part.contentID != nil {
            let disp = part.disposition?.lowercased()
            let isTextBody = part.contentType == "text/plain" || part.contentType == "text/html"
            if disp == "inline" || (!isTextBody && disp != "attachment") {
                into.append(part)
            }
        }
        for sub in part.parts { collectInlines(sub, into: &into) }
    }

    // MARK: - CID resolution

    public func partByContentID(_ cid: String) -> Part? {
        let clean = cid.trimmingCharacters(in: CharacterSet(charactersIn: "<> \t\r\n"))
        return contentIDIndex[clean]
    }

    private static func walk(_ part: Part, _ visit: (Part) -> Void) {
        visit(part)
        for sub in part.parts { walk(sub, visit) }
    }
}
