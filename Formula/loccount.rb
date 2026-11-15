class Loccount < Formula
  desc "Count source lines of code (SLOC) and logical lines of code (LLOC)"
  homepage "https://gitlab.com/esr/loccount"
  url "https://gitlab.com/esr/loccount/-/archive/2.28/loccount-2.28.tar.gz"
  sha256 "cebec700df9e9e78458a9a13ce9b691f811e7f060c5e866208ea160ed2dd211e"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/slop-bucket/homebrew-tap/releases/download/loccount-2.28"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "e5291ac855594a9c9420ce194d7116813ccd0d85295b1b62d3658eabbb7dd058"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "05a5f10b68d038e906fe91fb236c82067b5bf43775204650c396f95401f5af33"
  end

  depends_on "asciidoctor" => :build
  depends_on "go" => :build
  depends_on "python@3.15" => :build
  depends_on "ruamel-yaml" => :build

  def install
    system "go", "generate"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
    system "asciidoctor", "-D.", "-a", "nofooter", "-b", "manpage", "loccount.adoc"
    man1.install "loccount.1"
  end

  test do
    assert_equal "loccount #{version}\n", shell_output("#{bin}/loccount -V")

    (testpath/"hello.c").write <<~C
      #include <stdio.h>
      int main(void) {
        return 0;
      }
    C
    output = shell_output("#{bin}/loccount #{testpath}/hello.c")
    assert_match(/\bC\b/, output)
  end
end
