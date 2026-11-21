import XCTest
@testable import EMLCore

final class MSGTests: XCTestCase {

    private func sampleURL() throws -> URL {
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle(for: MSGTests.self)
#endif
        return try XCTUnwrap(
            bundle.url(forResource: "sample", withExtension: "msg", subdirectory: "Fixtures")
                ?? bundle.url(forResource: "sample", withExtension: "msg"),
            "sample.msg fixture must be bundled with tests"
        )
    }

    private func loadSample() throws -> Message {
        try Message(url: sampleURL())
    }

    func testRejectsInvalidSectorShifts() throws {
        let sample = try Data(contentsOf: sampleURL())
        for (offset, value) in [(30, UInt8(40)), (32, UInt8(7))] {
            var data = sample
            data[offset] = value
            XCTAssertNil(MSG.parse(data))
        }
    }

    func testTruncatedSampleDoesNotCrash() throws {
        let data = try Data(contentsOf: sampleURL())
        XCTAssertNil(MSG.parse(Data(data.prefix(1024))))
    }

    func testReadsFATFromCyclicDIFATChain() throws {
        var data = try Data(contentsOf: sampleURL())
        let sectorSize = 512
        let difatSector = UInt32(data.count / sectorSize - 1)
        let fatSector = data[76..<80]
        data.replaceSubrange(76..<80, with: [UInt8](repeating: 0xFF, count: 4))
        func bytes(_ value: UInt32) -> [UInt8] {
            (0..<4).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) }
        }
        data.replaceSubrange(68..<72, with: bytes(difatSector))
        data.replaceSubrange(72..<76, with: bytes(2))
        data.append(contentsOf: fatSector)
        data.append(contentsOf: [UInt8](repeating: 0xFF, count: sectorSize - 8))
        data.append(contentsOf: bytes(difatSector))
        let part = try XCTUnwrap(MSG.parse(data))
        XCTAssertTrue(part.rawHeaders.contains { $0.0 == "Subject" && $0.1 == "Test Outlook message with attachments" })
    }

    func testDetectsCFBMagic() {
        let cfb = Data([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, 0x00, 0x00])
        XCTAssertTrue(MSG.isMSG(cfb))
        XCTAssertFalse(MSG.isMSG(Data("From: a@b\r\n".utf8)))
    }

    func testHeadersParsed() throws {
        let msg = try loadSample()
        XCTAssertEqual(msg.subject, "Test Outlook message with attachments")
        XCTAssertEqual(msg.from, "Example, Alice <alice@example.com>")
        XCTAssertEqual(msg.to, "Bob Example <bob@example.com>, Logan, Julia <julia@example.com>")
        XCTAssertEqual(msg.cc, "Carol Example <carol@example.com>")
    }

    func testDisplayRecipientsFallbackWithoutStorages() throws {
        var data = try Data(contentsOf: sampleURL())
        let name = Data("__recip_version1.0_#".utf16.flatMap { [UInt8($0 & 0xff), UInt8($0 >> 8)] })
        var search = data.startIndex..<data.endIndex
        while let range = data.range(of: name, in: search) {
            data[range.lowerBound] = UInt8(ascii: "X")
            search = range.upperBound..<data.endIndex
        }
        let part = try XCTUnwrap(MSG.parse(data))
        XCTAssertTrue(part.rawHeaders.contains { $0.0 == "To" && $0.1 == "Bob Example <bob@example.com>" })
        XCTAssertTrue(part.rawHeaders.contains { $0.0 == "Cc" && $0.1 == "Carol Example <carol@example.com>" })
    }

    func testDateDecodedFromRootProperties() throws {
        let msg = try loadSample()
        XCTAssertEqual(msg.date, "Thu, 16 Apr 2026 14:30:00 +0000")
    }

    func testDatePriority() {
        XCTAssertEqual(MSG.preferredDate(["0039": "submit", "0E06": "delivery", "3007": "creation"]), "submit")
        XCTAssertEqual(MSG.preferredDate(["0E06": "delivery", "3007": "creation"]), "delivery")
        XCTAssertEqual(MSG.preferredDate(["3007": "creation"]), "creation")
        XCTAssertNil(MSG.preferredDate([:]))
    }

    func testPlainBodyDecoded() throws {
        let msg = try loadSample()
        let body = try XCTUnwrap(msg.plainBody)
        XCTAssertTrue(body.contains("synthetic Outlook .msg test fixture"))
    }

    func testHtmlBodyDecoded() throws {
        let msg = try loadSample()
        let html = try XCTUnwrap(msg.htmlBody)
        XCTAssertTrue(html.contains(#"cid:logo@example"#))
        XCTAssertTrue(html.contains("<strong>synthetic</strong>"))
    }

    func testAttachmentDecoded() throws {
        let msg = try loadSample()
        let atts = msg.attachments
        XCTAssertEqual(atts.count, 1)
        let pdf = try XCTUnwrap(atts.first)
        XCTAssertEqual(pdf.filename, "agenda.pdf")
        XCTAssertEqual(pdf.contentType, "application/pdf")
        XCTAssertTrue(pdf.decodedBody().starts(with: Data("%PDF-".utf8)))
    }

    func testInlineImageResolvedByCID() throws {
        let msg = try loadSample()
        let inline = try XCTUnwrap(msg.partByContentID("logo@example"))
        XCTAssertEqual(inline.filename, "logo.png")
        XCTAssertEqual(inline.contentType, "image/png")
        XCTAssertFalse(inline.decodedBody().isEmpty)
    }
}
