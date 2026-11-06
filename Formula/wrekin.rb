# Homebrew formula for the Wrekin agent, rendered by packaging/homebrew/render.sh
# from a release's checksums.txt. A formula rather than a cask because
# `brew services` (the `service` block below) is what runs the daemon.
class Wrekin < Formula
  desc "Teleport a Claude Code Cloud session onto one of your own machines, from Claude"
  homepage "https://wrekin.platyplus.io"
  version "0.2.5"
  license "MIT"

  livecheck do
    url "https://github.com/plmercereau/wrekin"
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.2.5/wrekin_0.2.5_darwin_arm64.tar.gz"
      sha256 "94a061043b277b484f7dc23623ea8e197ba64fabd450e455a9ef233b09b0d2fb"
    end
    on_intel do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.2.5/wrekin_0.2.5_darwin_amd64.tar.gz"
      sha256 "41158d2c9f579ac81c53fd1f7d2051d36335cd4dc7381b29a1c2c11ccf9c663a"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.2.5/wrekin_0.2.5_linux_arm64.tar.gz"
      sha256 "f2184c74ff1f7e5c31a200dd665466daaeaa35a6545434b999af8b74748ac3bf"
    end
    on_intel do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.2.5/wrekin_0.2.5_linux_amd64.tar.gz"
      sha256 "2ed884a39175e3f7212ce6fcf445969b4d35a6fc57965185811e58b49c9418f3"
    end
  end

  # The daemon execs `git`, `tmux` and `claude` by name.
  # - tmux is a formula: a dependency.
  # - git is not declared: Homebrew itself requires git (Xcode's Command Line
  #   Tools on macOS, the distribution's package on Linux), so every machine
  #   that runs brew has one, and the git formula would be a second, large git.
  # - Claude Code is a cask (`claude-code`, macOS) or the native installer, and
  #   a formula can depend on neither: the caveats ask the user to install it.
  depends_on "tmux"

  def install
    bin.install "wrekin"
  end

  def caveats
    <<~EOS
      wrekin runs Claude Code (the `claude` command), which it does not install.
      Pick one:
        brew install --cask claude-code                   # macOS
        curl -fsSL https://claude.ai/install.sh | bash    # native installer, macOS and Linux

      Then pair this machine with your Wrekin account and start the daemon:
        wrekin auth
        brew services start wrekin

      The service looks for claude, tmux and git in ~/.local/bin, #{HOMEBREW_PREFIX}/bin
      and the system directories. Its output goes to #{var}/log/wrekin.log;
      `wrekin logs` shows the daemon's own log.
    EOS
  end

  service do
    run [opt_bin/"wrekin", "daemon"]
    keep_alive true
    # launchd starts agents with PATH=/usr/bin:/bin:/usr/sbin:/sbin and
    # systemd --user with a similar minimum: neither sees Homebrew's prefix
    # (tmux, the claude-code cask) nor ~/.local/bin (Claude Code's native
    # installer, which keeps itself up to date). The user's own installation
    # comes first.
    environment_variables PATH: "#{Dir.home}/.local/bin:#{std_service_path_env}"
    log_path var/"log/wrekin.log"
    error_log_path var/"log/wrekin.log"
    working_dir HOMEBREW_PREFIX
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wrekin --version")
  end
end
