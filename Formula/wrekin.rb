# Homebrew formula for the Wrekin agent, rendered by packaging/homebrew/render.sh
# from a release's checksums.txt. A formula rather than a cask because
# `brew services` (the `service` block below) is what runs the daemon.
class Wrekin < Formula
  desc "Teleport a Claude Code Cloud session onto one of your own machines, from Claude"
  homepage "https://wrekin.platyplus.io"
  version "0.2.0"
  license "MIT"

  livecheck do
    url "https://github.com/plmercereau/wrekin"
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.2.0/wrekin_0.2.0_darwin_arm64.tar.gz"
      sha256 "cd46f7fcd5e1d232e566d2fe0ea6e659c63f2c6217dfece8b992d8a3711b7733"
    end
    on_intel do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.2.0/wrekin_0.2.0_darwin_amd64.tar.gz"
      sha256 "781d5c2315ad2ab43381e9f2fc5a887603262f0a762598f7c67bfc849417abd6"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.2.0/wrekin_0.2.0_linux_arm64.tar.gz"
      sha256 "64318ff9b6ea0e6321a1aa2b6a7362660255438930d124c527163c764e47e218"
    end
    on_intel do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.2.0/wrekin_0.2.0_linux_amd64.tar.gz"
      sha256 "24c68f4df0c63b804f2c95c838f7130bfce031ad702e763523617e1ed545f85d"
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
