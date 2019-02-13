# Description:
#   Build rule for Python and Numpy.
#   This rule works for Debian and Ubuntu. Other platforms might keep the
#   headers in different places, cf. 'How to build DeepMind Lab' in build.md.

cc_library(
    name = "python",
    hdrs = glob([
        "include/python3.5/*.h",
        "lib/python3/dist-packages/numpy/core/include/numpy/*.h",
    ]),
    includes = [
        "include/python3.5",
        "lib/python3/dist-packages/numpy/core/include",
    ],
    visibility = ["//visibility:public"],
)
