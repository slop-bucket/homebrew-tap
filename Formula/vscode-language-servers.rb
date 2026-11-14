class VscodeLanguageServers < Formula
  desc "CSS/LESS/SCSS, HTML, and JSON language servers from VS Code"
  homepage "https://github.com/microsoft/vscode"
  url "https://github.com/microsoft/vscode/archive/refs/tags/1.146.0.tar.gz"
  sha256 "7a2fadb7ba458eaac03da1be1d70aa70903fa9377f7f3a367facef3e237c1bb0"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/slop-bucket/homebrew-tap/releases/download/vscode-language-servers-1.146.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "0f6fa63556be1d33a79708cbb21e6b220f33235c50dde849bb6e3538526bd478"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "b1ebeb8c7cc9c5597d19f5010fbc7451867f265a6d9e719d33aac07f85a526d5"
  end

  depends_on "pnpm" => :build
  depends_on "typescript" => :build
  depends_on "node"

  SERVERS = %w[css json html].freeze

  def install
    inreplace "extensions/json-language-features/server/tsconfig.json" do |s|
      s.gsub!(/^\s*"sourceMap": true,\n/, "")
      s.gsub!(%r{^\s*"sourceRoot": "\.\./src",\n}, "")
    end
    inreplace "extensions/json-language-features/server/src/node/jsonServerMain.ts",
              "fs.readFile(uri.fsPath, encoding)",
              "fs.readFile(uri.fsPath, encoding ?? null)"
    inreplace "extensions/html-language-features/server/src/modes/javascriptLibs.ts",
              "../../node_modules/typescript/lib",
              "node_modules/typescript/lib"

    pnpm_args = %W[
      --ignore-workspace
      --node-linker=hoisted
      --store-dir=#{buildpath}/.pnpm-store
    ]

    SERVERS.each do |lang|
      cd "extensions/#{lang}-language-features/server" do
        system "pnpm", "install", *pnpm_args
        if lang == "html"
          # HTML language server requires TypeScript 6's createLanguageService API at runtime.
          system "pnpm", "add", *pnpm_args, "typescript@npm:@typescript/typescript6"
        end
        system "tsc"
        rm_r("node_modules/@types") if (Pathname.pwd/"node_modules/@types").exist?
        items = %w[node_modules out package.json]
        items << "lib" if (Pathname.pwd/"lib").exist?
        (libexec/lang).install items
      end

      bin_name = "vscode-#{lang}-language-server"
      (bin/bin_name).write <<~SH
        #!/bin/sh
        exec "#{formula_opt_bin("node")}/node" "#{libexec}/#{lang}/out/node/#{lang}ServerNodeMain.js" "$@"
      SH
      chmod 0755, bin/bin_name
    end
  end

  test do
    require "open3"

    json = <<~JSON
      {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
          "processId": null,
          "rootUri": null,
          "capabilities": {}
        }
      }
    JSON

    input = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
    SERVERS.each do |lang|
      Open3.popen2(bin/"vscode-#{lang}-language-server", "--stdio") do |stdin, stdout, wait_thr|
        stdin.write(input)
        stdin.flush
        header = stdout.gets("\r\n\r\n")
        assert_match(/Content-Length: \d+/, header)
        length = header[/Content-Length: (\d+)/, 1].to_i
        body = stdout.read(length)
        assert_match(/"capabilities":/, body)
        Process.kill("TERM", wait_thr.pid)
      end
    end
  end
end
