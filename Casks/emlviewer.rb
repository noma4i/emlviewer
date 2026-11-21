cask "emlviewer" do
  version "1.0.1"
  sha256 "209429ba09414a8a67a5355d9b62b7a6ada2a772df73c469ccb23111a1dd99d7"

  url "https://github.com/noma4i/emlviewer/releases/download/v#{version}/EMLViewer.app.zip"
  name "EMLViewer"
  desc "Minimalist .eml viewer for macOS"
  homepage "https://github.com/noma4i/emlviewer"

  depends_on macos: ">= :ventura"

  app "EMLViewer.app"

  zap trash: [
    "~/Library/Preferences/com.noma4i.EMLViewer.plist",
    "~/Library/Application Support/EMLViewer",
    "~/Library/Caches/com.noma4i.EMLViewer",
    "~/Library/Saved Application State/com.noma4i.EMLViewer.savedState",
  ]
end
