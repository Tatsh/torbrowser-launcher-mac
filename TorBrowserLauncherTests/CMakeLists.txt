find_package(XCTest)
add_executable(${CMAKE_PROJECT_NAME}Tests TorBrowserLauncherTests.swift)
target_compile_options(
  ${CMAKE_PROJECT_NAME}Tests
  PRIVATE
    -Fsystem
    /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks
)
