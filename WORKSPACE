workspace(name = "bazel_pandoc")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "4329663fe6c523425ad4d3c989a8ac026b04e1acedeceb56aa4b190fa7f3973c",
    strip_prefix = "bazel-toolchains-bc09b995c137df042bb80a395b73d7ce6f26afbe",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/bc09b995c137df042bb80a395b73d7ce6f26afbe.tar.gz",
        "https://github.com/bazelbuild/bazel-toolchains/archive/bc09b995c137df042bb80a395b73d7ce6f26afbe.tar.gz",
    ],
)

load("//:repositories.bzl", "pandoc_repositories")

pandoc_repositories()

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")

rules_nixpkgs_dependencies()

load(
    "@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl",
    "nixpkgs_package",
    "nixpkgs_git_repository",
)

nixpkgs_git_repository(
    name = "nixpkgs",
    revision = "22.05",
    sha256 = "0f8c25433a6611fa5664797cd049c80faefec91575718794c701f3b033f2db01",
)

nixpkgs_package(
    name = "graphviz",
    repository = "@nixpkgs",
    build_file_content = """
package(default_visibility = [ "//visibility:public" ])
exports_files([
  "nix/bin/dot",
  "nix/bin/neato",
])

filegroup(
  name = "bin",
  srcs = glob(["nix/bin/*"]),
)

filegroup(
  name = "lib",
  srcs = glob(["nix/lib/**/*.so"]),
)
""")
