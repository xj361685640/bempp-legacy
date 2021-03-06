# Copyright (c) 2015, University College London
# All rights reserved.

# !!! DO NOT PLACE HEADER GUARDS HERE !!!

# Load used modules
include(hunter_add_version)
include(hunter_cmake_args)
include(hunter_download)
include(hunter_pick_scheme)
include(hunter_configuration_types)
include(hunter_cacheable)

hunter_cacheable(GBenchmark)

# List of versions here...
hunter_add_version(
    PACKAGE_NAME
    GBenchmark
    VERSION
    "1.0.0"
    URL
    "https://github.com/google/benchmark/archive/v1.0.0.tar.gz"
    SHA1
    4f778985dce02d2e63262e6f388a24b595254a93
)

hunter_add_version(
    PACKAGE_NAME
    GBenchmark
    VERSION
    "1.1.0"
    URL
    "https://github.com/mdavezac/benchmark/archive/v1.1.0.tar.gz"
    SHA1
    772372564531dc0023037367a122391326bd1dc0
)

hunter_cmake_args(GBenchmark CMAKE_ARGS BENCHMARK_ENABLE_TESTING=OFF)
hunter_configuration_types(GBenchmark CONFIGURATION_TYPES Release)
# Pick a download scheme
hunter_pick_scheme(DEFAULT url_sha1_cmake)

# Download package.
# Two versions of library will be build:
#     * libexample_A.a
#     * libexample_Ad.a
hunter_download(PACKAGE_NAME GBenchmark)
