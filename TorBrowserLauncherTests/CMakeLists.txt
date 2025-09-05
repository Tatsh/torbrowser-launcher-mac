enable_testing()
find_package(XCTest REQUIRED)

set(LIBTBL tbl)
set(TEST_BUNDLE_NAME ${CMAKE_PROJECT_NAME}Tests)

add_library(
  ${LIBTBL} STATIC
  ../${CMAKE_PROJECT_NAME}/AppDelegate.swift ../${CMAKE_PROJECT_NAME}/LauncherWindow.swift
  ../${CMAKE_PROJECT_NAME}/Utils.swift)
xctest_add_bundle(
  ${TEST_BUNDLE_NAME}
  ${LIBTBL}
  UtilsBackgroundURLSessionTests.swift
  UtilsFindMatchInLinesTests.swift
  UtilsHDIAttachTests.swift
  UtilsHDIDetachTests.swift
  UtilsRemoveItemIfExistsTests.swift
  UtilsRemoveQuarantineExtendedAttributesTests.swift
  UtilsURLSessionWithProxyTests.swift)
xctest_add_test(app.${TEST_BUNDLE_NAME} ${TEST_BUNDLE_NAME})
target_link_libraries(${TEST_BUNDLE_NAME} PRIVATE ${LIBTBL})

foreach(_target ${LIBTBL} ${TEST_BUNDLE_NAME})
  set_target_properties(
    ${_target}
    PROPERTIES XCODE_ATTRIBUTE_ENABLE_TESTABILITY YES
               XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS YES
               XCODE_ATTRIBUTE_GCC_GENERATE_TEST_COVERAGE_FILES YES
               XCODE_ATTRIBUTE_GCC_INSTRUMENT_PROGRAM_FLOW_ARCS YES)
endforeach()
