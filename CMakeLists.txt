cmake_minimum_required(VERSION 3.31)
project(torbrowser-launcher-mac VERSION 0.0.2)

include(FeatureSummary)

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(BUILD_DOCS "Build documentation." OFF)
option(BUILD_TESTS "Build tests." OFF)

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

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

add_subdirectory(src)

install(TARGETS ${CMAKE_PROJECT_NAME})
include(CPack)
