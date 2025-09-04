cmake_minimum_required(VERSION 3.31)
project(
  TorBrowserLauncher
  VERSION 0.0.1
  LANGUAGES C Swift
  DESCRIPTION "Tor Browser Launcher for macOS, inspired by the Linux version."
  HOMEPAGE_URL "https://github.com/Tatsh/torbrowser-launcher-mac")
set(GITHUB_SLUG "torbrowser-launcher-mac")
set(BUNDLE_IDENTIFIER "sh.tat.${GITHUB_SLUG}")
set(PRODUCT_NAME "Tor Browser Launcher")
set(MIN_SYSTEM_VERSION "11.0")

include(GNUInstallDirs)

option(BUILD_TESTS "Build tests." OFF)
set(BUNDLE_INSTALL_PREFIX
    .
    CACHE FILEPATH "Install the bundle to a custom directory. This can be an absolute path or \
relative to CMAKE_INSTALL_PREFIX.")

set(CMAKE_OSX_DEPLOYMENT_TARGET ${MIN_SYSTEM_VERSION})
add_subdirectory(${CMAKE_PROJECT_NAME})
if(BUILD_TESTS)
  enable_testing()
  add_subdirectory(${CMAKE_PROJECT_NAME}Tests)
endif()
