function(add_language output prefix items)
  if(NOT ("${CMAKE_GENERATOR}" STREQUAL "Xcode"))
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/${prefix}")
    set(string_files)
    foreach(_src ${items})
      get_filename_component(_name "${_src}" NAME_WE)
      add_custom_command(
        OUTPUT "${CMAKE_BINARY_DIR}/${prefix}/${_name}.strings"
        COMMAND printf \\xFF\\xFE > "${CMAKE_BINARY_DIR}/${prefix}/${_name}.strings"
        COMMAND /usr/bin/iconv -f UTF-8 -t UTF-16LE "${CMAKE_CURRENT_SOURCE_DIR}/${_src}" >>
                "${CMAKE_BINARY_DIR}/${prefix}/${_name}.strings"
        DEPENDS "${_src}"
        VERBATIM)
      list(APPEND string_files "${CMAKE_BINARY_DIR}/${prefix}/${_name}.strings")
    endforeach()
    set("${output}"
        "${string_files}"
        PARENT_SCOPE)
  else()
    set("${output}"
        "${items}"
        PARENT_SCOPE)
  endif()
endfunction()

