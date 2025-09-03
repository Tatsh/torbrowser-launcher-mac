set(TBL_SRCS AppDelegate.swift LauncherWindow.swift Utils.swift Info.plist.in
Assets.xcassets/AccentColor.colorset/Contents.json
Assets.xcassets/AppIcon.appiconset/Contents.json
Assets.xcassets/Contents.json)
file(GLOB TBL_ICONS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Assets.xcassets/AppIcon.appiconset/*.png")

add_executable(${CMAKE_PROJECT_NAME} ${TBL_SRCS})
add_xib(Base.lproj/LauncherWindow.xib)
add_xib(Base.lproj/MainMenu.xib)
finalize_xibs(XIBS)
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${XIBS})
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${TBL_SRCS} ${TBL_ICONS})
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
  MACOSX_BUNDLE TRUE
  MACOSX_BUNDLE_GUI_IDENTIFIER ${BUNDLE_IDENTIFIER}
  MACOSX_BUNDLE_BUNDLE_NAME "Tor Browser Launcher"
  MACOSX_BUNDLE_BUNDLE_VERSION "${CMAKE_PROJECT_VERSION}"
  MACOSX_BUNDLE_SHORT_VERSION_STRING "${CMAKE_PROJECT_VERSION}"
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in"
  RESOURCE "${XIBS}"
)
set_source_files_properties(Assets.xcassets PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources
)
set_source_files_properties(Assets.xcassets/AccentColor.colorset/Contents.json PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources/Assets.xcassets/AccentColor.colorset
)
set_source_files_properties(Assets.xcassets/AppIcon.appiconset/Contents.json ${TBL_ICONS} PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources/Assets.xcassets/AppIcon.appiconset
    )
set_source_files_properties(Assets.xcassets/Contents.json PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources/Assets.xcassets
)
