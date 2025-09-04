cmake_minimum_required(VERSION 3.31)
project(
  TorBrowserLauncher
  VERSION 0.0.2
  LANGUAGES C Swift
  DESCRIPTION "Tor Browser Launcher for macOS, inspired by the Linux version."
  HOMEPAGE_URL "https://github.com/Tatsh/torbrowser-launcher-mac")
set(GITHUB_SLUG "torbrowser-launcher-mac")
set(BUNDLE_IDENTIFIER "sh.tat.${GITHUB_SLUG}")
set(PRODUCT_NAME "Tor Browser Launcher")
set(MIN_SYSTEM_VERSION "11.0")

include(GNUInstallDirs)

option(BUILD_DOCS "Build documentation." OFF)
option(BUILD_TESTS "Build tests." OFF)
set(BUNDLE_INSTALL_PREFIX
    .
    CACHE FILEPATH "Install the bundle to a custom directory. This can be an absolute path or \
relative to CMAKE_INSTALL_PREFIX.")

if(BUILD_DOCS)
  find_package(Doxygen REQUIRED)
  set(DOXYGEN_OUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in ${DOXYGEN_OUT} @ONLY)
  add_custom_target(
    docs
    COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/docs/html
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/doc/${CMAKE_PROJECT_NAME}-${CMAKE_PROJECT_VERSION})
endif()

set(CMAKE_OSX_DEPLOYMENT_TARGET ${MIN_SYSTEM_VERSION})
add_subdirectory(${CMAKE_PROJECT_NAME})
if(BUILD_TESTS)
  enable_testing()
  add_subdirectory(${CMAKE_PROJECT_NAME}Tests)
endif()
