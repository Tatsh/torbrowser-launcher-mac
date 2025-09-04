set(TBL_SRCS
    AppDelegate.swift
    LauncherWindow.swift
    Utils.swift
    Info.plist.in
    Assets.xcassets/AccentColor.colorset/Contents.json
    Assets.xcassets/AppIcon.appiconset/Contents.json
    Assets.xcassets/Contents.json
    Base.lproj/LauncherWindow.xib
    Base.lproj/MainMenu.xib)
set(TBL_XIBS)
set(TBL_STRINGS_EN en.lproj/LauncherWindow.strings en.lproj/MainMenu.strings)
set(TBL_STRINGS_ZH_HANS zh-Hans.lproj/LauncherWindow.strings zh-Hans.lproj/MainMenu.strings
                        zh-Hans.lproj/InfoPlist.strings zh-Hant.lproj/LauncherWindow.strings)
set(FINISHED_TBL_STRINGS_EN)
set(FINISHED_TBL_STRINGS_ZH_HANS)

function(add_language output prefix items)
  foreach(_src ${items})
    get_filename_component(_name "${_src}" NAME)
    add_custom_command(
      OUTPUT "${CMAKE_BINARY_DIR}/${prefix}/${_name}"
      COMMAND iconv -t UTF16LE "${_src}" -o "${CMAKE_BINARY_DIR}/${prefix}/${_name}"
      DEPENDS "${_src}"
      VERBATIM)
    list(APPEND "${output}" "${CMAKE_BINARY_DIR}/${_src}.strings")
  endforeach()
  set_source_files_properties(${output} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/${prefix}")
endfunction()

add_executable(${CMAKE_PROJECT_NAME} ${TBL_SRCS})
# Nibs
find_program(IBTOOL ibtool REQUIRED)
foreach(_src ${TBL_SRCS})
  if(_src MATCHES ".+\\.xib$")
    get_filename_component(_name "${_src}" NAME_WE)
    add_custom_command(
      OUTPUT "${_name}.nib"
      COMMAND ${IBTOOL} --compile "${_name}.nib" "${_src}"
      DEPENDS "${_src}"
      VERBATIM)
    list(APPEND TBL_XIBS "${_name}.nib")
  endif()
endforeach()
set_source_files_properties(${TBL_XIBS} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/Base.lproj)
# Localisation
add_language(FINISHED_TBL_STRINGS_EN en.lproj "${TBL_STRINGS_EN}")
add_language(FINISHED_TBL_STRINGS_ZH_HANS zh-Hans.lproj "${TBL_STRINGS_ZH_HANS}")
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${FINISHED_TBL_STRINGS_EN})
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${FINISHED_TBL_STRINGS_ZH_HANS})
# Assets
file(GLOB TBL_ICONS CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/Assets.xcassets/AppIcon.appiconset/*.png")
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${TBL_SRCS} ${TBL_ICONS})
set_target_properties(
  ${CMAKE_PROJECT_NAME}
  PROPERTIES MACOSX_BUNDLE TRUE
             MACOSX_BUNDLE_GUI_IDENTIFIER ${BUNDLE_IDENTIFIER}
             MACOSX_BUNDLE_BUNDLE_NAME "Tor Browser Launcher"
             MACOSX_BUNDLE_BUNDLE_VERSION "${CMAKE_PROJECT_VERSION}"
             MACOSX_BUNDLE_SHORT_VERSION_STRING "${CMAKE_PROJECT_VERSION}"
             MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in"
             RESOURCE "${TBL_XIBS}")
set_source_files_properties(Assets.xcassets PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
set_source_files_properties(
  Assets.xcassets/AccentColor.colorset/Contents.json
  PROPERTIES MACOSX_PACKAGE_LOCATION Resources/Assets.xcassets/AccentColor.colorset)
set_source_files_properties(
  Assets.xcassets/AppIcon.appiconset/Contents.json ${TBL_ICONS}
  PROPERTIES MACOSX_PACKAGE_LOCATION Resources/Assets.xcassets/AppIcon.appiconset)
set_source_files_properties(Assets.xcassets/Contents.json PROPERTIES MACOSX_PACKAGE_LOCATION
                                                                     Resources/Assets.xcassets)

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
    torbrowser-launcher-${CMAKE_PROJECT_VERSION}-${__cpack_system_name}-${CMAKE_BUILD_TYPE})
include(CPack)
