class Anyzig < Formula
  desc "Universal executables that run any version of zig and zls"
  homepage "https://github.com/marler8997/anyzig"
  url "https://github.com/marler8997/anyzig/archive/refs/tags/v2026_11_12.tar.gz"
  sha256 "5403be7549905990e98f036f920536cbf5948008a818cfb1587e408029333133"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:[._]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    root_url "https://github.com/slop-bucket/homebrew-tap/releases/download/anyzig-2026.11.12"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "e5ced3964d50e1d86037cff4534131ee62f9ed41f7394ff0d9eacf6386cd1427"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "9868c31a56c1cf95270a98cbd1a1991a59cb129fc87beec8843d700d47da1b91"
  end

  keg_only "it conflicts with zig and zls"

  depends_on "zig" => :build

  deny_network_access!

  def fetch
    system "zig", "build", "--fetch=all"
  end

  def install
    # zig-patch preserves the read-only permissions of Homebrew's Zig standard library.
    cp_r formula_opt_lib("zig")/"zig", buildpath/"zig-lib"
    chmod_R "u+w", buildpath/"zig-lib"
    ENV["ZIG_LIB_DIR"] = buildpath/"zig-lib"

    args = %W[-Dforce-version=v#{version.to_s.tr(".", "_")}]
    system "zig", "build", *args, *std_zig_args
    system "zig", "build", "install-zls", *args, *std_zig_args
  end

  test do
    assert_match "v#{version.to_s.tr(".", "_")}", shell_output("#{bin}/zig any version").strip
    assert_match "v#{version.to_s.tr(".", "_")}", shell_output("#{bin}/zls any version").strip
    system bin/"zig", "any", "list-installed"
    system bin/"zls", "any", "list-installed"
  end
end
