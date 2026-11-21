# Changelog

## [1.0.1] - 2026-11-21

### Added

- Ten color themes: Light, Dark, Solarized Light and Dark, Nord, Dracula, Gruvbox Dark, One Dark and Sepia. HTML mail is recolored to stay readable.
- Settings for message font family and text size.
- Setting to load or block remote images in HTML mail.
- Save All saves attachments to a folder you choose.
- Recipient addresses in Outlook .msg files.

### Changed

- Opened mail renders without delay, including on cold launch.
- Message dates are shown in the local time zone.
- Opening another file reuses the existing window, and the window size is restored between launches.
- Faster message parsing.

### Fixed

- RFC 2231 continuation decoding of attachment names.
- Header refresh when opening another message.
- Hardened Outlook .msg (CFB) sector parsing and attachment file name sanitizing.

## [1.0.0] - 2026-04-16

### Added

- Initial release of EMLViewer, a minimalist `.eml` and `.msg` viewer for macOS.
- MIME parser with RFC 2047 encoded-word, quoted-printable, base64, and charset decoding (UTF-8, Windows-125x, ISO-8859-\*).
- Nested `multipart/mixed`, `multipart/related`, and `multipart/alternative` support; inline image resolution via `cid:` URL scheme.
- Outlook `.msg` (Compound File Binary) support via a native CFB/MAPI reader, no external dependencies. Subject, sender, recipients and plain body are decoded from MAPI property streams.
- Finder association for both `.eml` and `.msg`, with a one-click Welcome action that registers EMLViewer as the default handler.
- SwiftUI UI: decoded headers, `WKWebView` HTML rendering, horizontal attachments bar with system file icons.
- Attachment actions: click to open in the associated app, "Download All" to `~/Downloads`, context menu "Save As...".
- Welcome screen with appearance picker (System / Light / Dark), GitHub button, version info.
- Light / Dark / System theme picker with persistence across app launches.
- Window size persisted across launches via SwiftData.
- Hidden title bar for a lighter look.
- `emlcheck` CLI companion that prints MIME tree, inline parts, and attachments.
- Makefile targets (`build`, `run`, `bundle`, `zip`, `install`, `test`, `icon`), ad-hoc signing, LaunchServices registration.
