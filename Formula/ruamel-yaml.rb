class RuamelYaml < Formula
  desc "YAML parser/emitter with round-trip preservation of comments and formatting"
  homepage "https://sourceforge.net/p/ruamel-yaml/"
  url "https://files.pythonhosted.org/packages/c7/3b/ebda527b56beb90cb7652cb1c7e4f91f48649fbcd8d2eb2fb6e77cd3329b/ruamel_yaml-0.19.1.tar.gz"
  sha256 "53eb66cd27849eff968ebf8f0bf61f46cdac2da1d1f3576dd4ccee9b25c31993"
  license "MIT"

  depends_on "python-setuptools" => :build
  depends_on "python@3.14" => [:build, :test]
  depends_on "python@3.15" => [:build, :test]

  def pythons
    deps.map(&:to_formula)
        .select { |f| f.name.start_with?("python@") }
        .sort_by(&:version)
  end

  def install
    pythons.each do |python|
      python3 = python.opt_libexec/"bin/python"
      system python3, "-m", "pip", "install", *std_pip_args(build_isolation: true), "."
    end
  end

  test do
    pythons.each do |python|
      python3 = python.opt_libexec/"bin/python"
      system python3, "-c", <<~PYTHON
        from ruamel.yaml import YAML
        yaml = YAML()
        data = yaml.load("key: [1, 2, 3]")
        assert data["key"] == [1, 2, 3]
      PYTHON
    end
  end
end
