# Homebrew formula for the Wrekin agent, rendered by packaging/homebrew/render.sh
# from a release's checksums.txt. A formula rather than a cask because
# `brew services` (the `service` block below) is what runs the daemon.
class Wrekin < Formula
  desc "Teleport a Claude Code Cloud session onto one of your own machines, from Claude"
  homepage "https://wrekin.platyplus.io"
  version "0.3.0"
  license "MIT"

  livecheck do
    url "https://github.com/plmercereau/wrekin"
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.3.0/wrekin_0.3.0_darwin_arm64.tar.gz"
      sha256 "11cec6145bfc58f88edf61b23031cd9308b33879b6cb543fadb81420c2a5c983"
    end
    on_intel do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.3.0/wrekin_0.3.0_darwin_amd64.tar.gz"
      sha256 "1dc94f6b203b105484e79ceeba8f784a1a69c6c4223eb833303b91ad711de124"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.3.0/wrekin_0.3.0_linux_arm64.tar.gz"
      sha256 "b2476c5a0d6ec7e759a8a7551435da466c6d8c2a75b5f9af9d2bb5b89925b17c"
    end
    on_intel do
      url "https://github.com/plmercereau/wrekin/releases/download/v0.3.0/wrekin_0.3.0_linux_amd64.tar.gz"
      sha256 "af2eeceacba4be56cc9780f4873de0ed3c17a9abbdeb2ef2208aeec5ee69f331"
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
    # bash, zsh and fish completions, from cobra's `wrekin completion <shell>`.
    generate_completions_from_executable(bin/"wrekin", "completion")
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
