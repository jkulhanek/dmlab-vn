workspace(name = "org_deepmind_lab")
BAZEL_VERSION = "0.19.2"
BAZEL_VERSION_SHA = "11234cce4f6bdc62c3ac688f41c7b5c178eecb6f7e2c4ba0bcf00ba8565b1d19"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "com_google_googletest",
    strip_prefix = "googletest-master",
    urls = ["https://github.com/google/googletest/archive/master.zip"],
)

http_archive(
    name = "com_google_absl",
    strip_prefix = "abseil-cpp-master",
    urls = ["https://github.com/abseil/abseil-cpp/archive/master.zip"],
)

http_archive(
    name = "eigen_archive",
    build_file = "@//:eigen.BUILD",
    sha256 = "9a01fed6311df359f3f9af119fcf298a3353aef7d1b1bc86f6c8ae0ca6a2f842",
    strip_prefix = "/eigen-eigen-5d5dd50b2eb6",
    urls = [
        "https://mirror.bazel.build/bitbucket.org/eigen/eigen/get/5d5dd50b2eb6.zip",
        "https://bitbucket.org/eigen/eigen/get/5d5dd50b2eb6.zip",
    ],
)

http_archive(
    name = "glib_archive",
    build_file = "@//:glib.BUILD",
    sha256 = "0cbb3d31c9d181bbcc97cba3d9dbe3250f75e2da25e5f7c8bf5a993fe54baf6a",
    strip_prefix = "glib-2.55.1",
    urls = [
        "https://mirror.bazel.build/ftp.gnome.org/pub/gnome/sources/glib/2.55/glib-2.55.1.tar.xz",
        "https://ftp.gnome.org/pub/gnome/sources/glib/2.55/glib-2.55.1.tar.xz",
    ],
)

http_archive(
    name = "jpeg_archive",
    build_file = "@//:jpeg.BUILD",
    sha256 = "650250979303a649e21f87b5ccd02672af1ea6954b911342ea491f351ceb7122",
    strip_prefix = "jpeg-9c",
    urls = ["http://www.ijg.org/files/jpegsrc.v9c.tar.gz"],
)

http_archive(
    name = "libxml_archive",
    build_file = "@//:libxml.BUILD",
    sha256 = "f63c5e7d30362ed28b38bfa1ac6313f9a80230720b7fb6c80575eeab3ff5900c",
    strip_prefix = "libxml2-2.9.7",
    urls = [
        "https://mirror.bazel.build/xmlsoft.org/sources/libxml2-2.9.7.tar.gz",
        "http://xmlsoft.org/sources/libxml2-2.9.7.tar.gz",
    ],
)

http_archive(
    name = "png_archive",
    build_file = "@//:png.BUILD",
    sha256 = "7ffa5eb8f9f3ed23cf107042e5fec28699718916668bbce48b968600475208d3",
    strip_prefix = "libpng-1.6.34",
    urls = [
        "https://mirror.bazel.build/github.com/glennrp/libpng/archive/v1.6.34.zip",
        "https://github.com/glennrp/libpng/archive/v1.6.34.zip",
    ],
)

http_archive(
    name = "zlib_archive",
    build_file = "@//:zlib.BUILD",
    sha256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
    strip_prefix = "zlib-1.2.11",
    urls = [
        "https://mirror.bazel.build/zlib.net/zlib-1.2.11.tar.gz",
        "https://zlib.net/zlib-1.2.11.tar.gz",
    ],
)

http_archive(
    name = "six_archive",
    build_file = "@//:six.BUILD",
    sha256 = "105f8d68616f8248e24bf0e9372ef04d3cc10104f1980f54d57b2ce73a5ad56a",
    strip_prefix = "six-1.10.0",
    urls = [
        "https://mirror.bazel.build/pypi.python.org/packages/source/s/six/six-1.10.0.tar.gz",
        "https://pypi.python.org/packages/source/s/six/six-1.10.0.tar.gz",
    ],
)

http_archive(
    name = "lua_archive",
    build_file = "@//:lua.BUILD",
    sha256 = "2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333",
    strip_prefix = "lua-5.1.5/src",
    urls = [
        "https://mirror.bazel.build/www.lua.org/ftp/lua-5.1.5.tar.gz",
        "https://www.lua.org/ftp/lua-5.1.5.tar.gz",
    ],
)

http_archive(
    name = "rules_cc",
    strip_prefix = "rules_cc-master",
    urls = ["https://github.com/bazelbuild/rules_cc/archive/master.zip"],
)

# TODO: Replace with hermetic build
new_local_repository(
    name = "sdl_system",
    build_file = "sdl.BUILD",
    path = "/usr",
)

new_local_repository(
    name = "python_system",
    build_file = "python.BUILD",
    path = "/usr",
)
