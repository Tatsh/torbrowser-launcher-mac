set(TBL_NIBS)
set(TBL_XIBS Base.lproj/LauncherWindow.xib Base.lproj/MainMenu.xib)
set(TBL_SRCS AppDelegate.swift Info.plist.in LauncherWindow.swift torbrowser.icns)
set(TBL_STRINGS_EN en.lproj/LauncherWindow.strings en.lproj/MainMenu.strings)
set(TBL_STRINGS_ZH_HANS
    ../${LIBTBL}/zh-Hans.lproj/Lib.strings zh-Hans.lproj/InfoPlist.strings
    zh-Hans.lproj/LauncherWindow.strings zh-Hans.lproj/Localizable.strings
    zh-Hans.lproj/MainMenu.strings)

add_executable(${CMAKE_PROJECT_NAME} ${TBL_SRCS} ${TBL_XIBS})
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ${LIBTBL})
set_target_properties(
  ${CMAKE_PROJECT_NAME}
  PROPERTIES MACOSX_BUNDLE TRUE
             MACOSX_BUNDLE_BUNDLE_NAME "${PRODUCT_NAME}"
             MACOSX_BUNDLE_BUNDLE_VERSION "${CMAKE_PROJECT_VERSION}"
             MACOSX_BUNDLE_GUI_IDENTIFIER "${BUNDLE_IDENTIFIER}"
             MACOSX_BUNDLE_ICON_FILE "torbrowser.icns"
             MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in"
             MACOSX_BUNDLE_SHORT_VERSION_STRING "${CMAKE_PROJECT_VERSION}"
             OUTPUT_NAME "${PRODUCT_NAME}"
             RESOURCE "${TBL_XIBS}"
             XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${BUNDLE_IDENTIFIER}"
             XCODE_ATTRIBUTE_SWIFT_VERSION "5.0")
set_source_files_properties(torbrowser.icns PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
# Nibs
if(NOT ("${CMAKE_GENERATOR}" STREQUAL "Xcode"))
  find_program(IBTOOL ibtool REQUIRED)
  foreach(_src ${TBL_XIBS})
    get_filename_component(_name "${_src}" NAME_WE)
    get_filename_component(_full_path "${_src}" ABSOLUTE)
    add_custom_command(
      COMMAND ${IBTOOL} --compile "${CMAKE_BINARY_DIR}/${_name}.nib" "${_full_path}"
      DEPENDS "${_src}"
      OUTPUT "${CMAKE_BINARY_DIR}/${_name}.nib"
      VERBATIM)
    list(APPEND TBL_NIBS "${CMAKE_BINARY_DIR}/${_name}.nib")
  endforeach()
  set_source_files_properties(${TBL_NIBS} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/Base.lproj)
  target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${TBL_SRCS} ${TBL_XIBS})
endif()
# Localisation
add_language(FINISHED_TBL_STRINGS_EN en.lproj "${TBL_STRINGS_EN}")
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${TBL_SRCS} ${FINISHED_TBL_STRINGS_EN})
set_source_files_properties(${FINISHED_TBL_STRINGS_EN} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
add_language(FINISHED_TBL_STRINGS_ZH_HANS zh-Hans.lproj "${TBL_STRINGS_ZH_HANS}")
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${FINISHED_TBL_STRINGS_ZH_HANS})
set_source_files_properties(${FINISHED_TBL_STRINGS_ZH_HANS} PROPERTIES MACOSX_PACKAGE_LOCATION
                                                                       Resources)

install(TARGETS ${CMAKE_PROJECT_NAME} BUNDLE DESTINATION ${BUNDLE_INSTALL_PREFIX})
set(CPACK_GENERATOR DragNDrop ZIP)
set(CPACK_PACKAGE_VENDOR Tatsh)
set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_SOURCE_DIR}/LICENSE.txt)
set(__cpack_system_name ${CMAKE_SYSTEM_NAME})
if(CMAKE_APPLE_SILICON_PROCESSOR)
  set(__cpack_system_name Darwin-arm64)
else()
  set(__cpack_system_name Darwin-x86_64)
endif()
set(CPACK_PACKAGE_FILE_NAME
    ${GITHUB_SLUG}-${CMAKE_PROJECT_VERSION}-${__cpack_system_name}-${CMAKE_BUILD_TYPE})
include(CPack)
