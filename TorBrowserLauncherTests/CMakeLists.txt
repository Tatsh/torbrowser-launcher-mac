enable_testing()
find_package(XCTest REQUIRED)

set(TEST_BUNDLE_NAME ${CMAKE_PROJECT_NAME}Tests)

xctest_add_bundle(
  ${TEST_BUNDLE_NAME}
  ${LIBTBL}
  DMGManagerTest.swift
  DownloaderTest.swift
  InstallerTest.swift
  SettingsTest.swift
  UtilsTest.swift)
xctest_add_test(app.${TEST_BUNDLE_NAME} ${TEST_BUNDLE_NAME})
target_link_libraries(${TEST_BUNDLE_NAME} PRIVATE ${LIBTBL})

foreach(_target ${CMAKE_PROJECT_NAME} ${LIBTBL} ${TEST_BUNDLE_NAME})
  set_target_properties(${_target} PROPERTIES XCODE_ATTRIBUTE_ENABLE_TESTABILITY YES)
  target_compile_definitions(${_target} PRIVATE TESTING=1)
  target_compile_options(${_target} PRIVATE -profile-generate -profile-coverage-mapping)
  target_link_options(${_target} PRIVATE -fprofile-instr-generate -fcoverage-mapping)
endforeach()
