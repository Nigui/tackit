# Homebrew cask template. Publish to a tap repo (e.g. homebrew-tap) and fill in
# OWNER/REPO + the released DMG's sha256 (printed by scripts/package.sh).
cask "tackit" do
  version "0.0.1"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/OWNER/REPO/releases/download/v#{version}/Tackit.dmg"
  name "Tackit"
  desc "Blazing-fast, keyboard-driven sticky notes for macOS"
  homepage "https://github.com/OWNER/REPO"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "Tackit.app"

  zap trash: [
    "~/Library/Application Support/Tackit",
    "~/Library/Preferences/app.tackit.mac.plist",
    "~/Library/Logs/tackit-m0.log",
  ]
end
