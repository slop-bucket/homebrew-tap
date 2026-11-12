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

  depends_on "node"
  depends_on "typescript"

  SERVERS = %w[css html json].freeze

  def install
    SERVERS.each do |lang|
      cd "extensions/#{lang}-language-features/server" do
        system "npm", "ci"
        system "tsc"
        rm_r("node_modules/@types") if (Pathname.pwd/"node_modules/@types").exist?
        (libexec/lang).install "node_modules", "out", "package.json"
      end

      bin_name = "vscode-#{lang}-language-server"
      (bin/bin_name).write <<~SH
        #!/bin/sh
        exec "#{formula_opt_bin("node")}/node" "#{libexec}/#{lang}/out/node/#{lang}ServerMain.js" "$@"
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
        Process.kill("TERM", wait_thr.pid)
      end
    end
  end
end
