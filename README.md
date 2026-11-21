<p align="center">
  <img src="Resources/AppIcon.source.png" alt="EMLViewer" width="180">
</p>

# EML/MSG Viewer

Open `.eml` and Outlook `.msg` files on your Mac without a mail client. The app is sandboxed, requires no account, and collects no data.

<p align="center">
  <a href="AppStore/previews/en-US/preview.mp4"><img src="AppStore/previews/en-US/preview.gif" alt="EML/MSG Viewer demo" width="720"></a>
</p>

## Features

- `.eml` MIME parsing with encoded headers, quoted-printable, base64, and charset decoding
- Outlook `.msg` Compound File Binary parsing for headers, message bodies, inline images, and attachments
- Decoded From, To, Cc, Subject, and Date headers, with parsed dates shown in the local time zone
- HTML messages with inline `cid:` images and a plain-text fallback
- Attachments bar to open files in their default app or save all attachments to a folder you choose
- 10 themes: System, Light, Dark, Solarized Light, Solarized Dark, Nord, Dracula, Gruvbox Dark, One Dark, and Sepia. HTML mail is recolored for readability.
- Settings for message font family, text size, theme, and remote image loading
- Set the app as default for `.eml` and `.msg` from the welcome window
- Window size remembered across launches
- `emlcheck` CLI for inspecting MIME trees

## Install

### Mac App Store

[Download from the Mac App Store](https://apps.apple.com/app/id6762357866).

### Homebrew

```bash
brew tap noma4i/emlviewer https://github.com/noma4i/emlviewer
brew install --cask emlviewer
```

### Download

Download `EMLViewer.app.zip` from [Releases](https://github.com/noma4i/emlviewer/releases).

## Requirements

- macOS 14.0+
- Swift 5.9+
- Xcode 15+

## Build

The `.app` is built by Xcode (`xcodebuild`) and written to `dist/`.

```bash
make bundle      # dist/EMLViewer.app (release, ad-hoc signed)
make run         # debug build + launch
make install     # copy into /Applications
make preview     # App Store preview
make screenshots # App Store screenshots
```

### Xcode IDE

```bash
open EMLViewer.xcodeproj
```

## Test

```bash
make test
```

## Privacy

The app is sandboxed and has no analytics. Remote images can be blocked in Settings.

## Links

[Site](https://emlviewer.noma4i.com/) | [Support](https://emlviewer.noma4i.com/support) | [Privacy](https://emlviewer.noma4i.com/privacy)

## License

MIT
