# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_mwebd_library VERSION 0.0.1 LANGUAGES C)

add_library(flutter_mwebd SHARED
  "flutter_mwebd.c"
)

set_target_properties(flutter_mwebd PROPERTIES
        PUBLIC_HEADER flutter_mwebd.h
        OUTPUT_NAME "flutter_mwebd"
)

target_compile_definitions(flutter_mwebd PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(flutter_mwebd PRIVATE "-Wl,-z,max-page-size=16384")
endif()

get_filename_component(PLUGIN_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)

if (DEFINED BUILD_FOR_SYSTEM_NAME)
  set(DART_BUILD_DIR "${PLUGIN_ROOT}/src/build")
  set(BUILD_OUTPUT_DIR "${DART_BUILD_DIR}/${BUILD_FOR_SYSTEM_NAME}")

  if (BUILD_FOR_SYSTEM_NAME STREQUAL "linux")
    set(GO_SHARED_LIB "${BUILD_OUTPUT_DIR}/libmwebd.so")
  elseif (BUILD_FOR_SYSTEM_NAME STREQUAL "windows")
    set(GO_SHARED_LIB "${BUILD_OUTPUT_DIR}/libmwebd.dll")
  elseif (BUILD_FOR_SYSTEM_NAME STREQUAL "android")
    set(ANDROID_ABI_SUBDIR "${ANDROID_ABI}")
    set(BUILD_OUTPUT_DIR "${BUILD_OUTPUT_DIR}/${ANDROID_ABI_SUBDIR}")
    set(GO_SHARED_LIB "${BUILD_OUTPUT_DIR}/libmwebd.so")
    set(JNI_LIBS_DIR "${PLUGIN_ROOT}/android/src/main/jniLibs/${ANDROID_ABI}")
  endif ()

  set(GO_HEADER "${BUILD_OUTPUT_DIR}/libmwebd.h")
  set(HEADER_DEST "${PLUGIN_ROOT}/src/libmwebd.h")

  if (BUILD_FOR_SYSTEM_NAME STREQUAL "android")

    if (ANDROID_ABI STREQUAL "armeabi-v7a" OR ANDROID_ABI STREQUAL "x86")
      set(HEADER_DEST "${PLUGIN_ROOT}/src/libmwebd_32.h")
    endif ()

    add_custom_command(
            OUTPUT "${GO_SHARED_LIB}"
            COMMAND dart tool/build.dart
            -p "${BUILD_FOR_SYSTEM_NAME}"
            -o "${BUILD_OUTPUT_DIR}"
            -n "${CMAKE_ANDROID_NDK}"
            -a "${ANDROID_PLATFORM}"
            -b "${DART_BUILD_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${GO_HEADER}" "${HEADER_DEST}"
            WORKING_DIRECTORY "${PLUGIN_ROOT}"
            COMMENT "Building Go library for Android (${ANDROID_ABI}) using Dart"
            VERBATIM
    )

    add_custom_command(
            TARGET flutter_mwebd POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${JNI_LIBS_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${GO_SHARED_LIB}" "${JNI_LIBS_DIR}/libmwebd.so"
            COMMENT "Copying libmwebd.so to jniLibs for Android (${ANDROID_ABI})"
    )
  else ()
    # Generic Dart build for non-Android
    add_custom_command(
            OUTPUT "${GO_SHARED_LIB}"
            COMMAND dart tool/build.dart
            -p "${BUILD_FOR_SYSTEM_NAME}"
            -o "${BUILD_OUTPUT_DIR}"
            -b "${DART_BUILD_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${GO_HEADER}" "${HEADER_DEST}"
            WORKING_DIRECTORY "${PLUGIN_ROOT}"
            COMMENT "Building Go library for ${BUILD_FOR_SYSTEM_NAME} using Dart"
            VERBATIM
    )
  endif ()

  if (GO_SHARED_LIB)
    add_custom_target(
            go_build ALL
            DEPENDS "${GO_SHARED_LIB}"
    )

    add_library(mwebd_external SHARED IMPORTED GLOBAL)
    set_target_properties(mwebd_external PROPERTIES
            IMPORTED_LOCATION "${GO_SHARED_LIB}"
    )

    add_dependencies(mwebd_external go_build)
    add_dependencies(flutter_mwebd mwebd_external)


    if (NOT BUILD_FOR_SYSTEM_NAME STREQUAL "android")
      target_link_libraries(flutter_mwebd PRIVATE mwebd_external)
    endif ()
  else ()
    message(STATUS "Go build failed: GO_SHARED_LIB not set")
  endif ()
else ()
  message(STATUS "Skipping Go build: unspecified BUILD_FOR_SYSTEM_NAME")
endif ()


