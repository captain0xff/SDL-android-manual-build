cmake_minimum_required (VERSION 3.28)

project (create-dex NONE)

find_package(Java REQUIRED)
include(UseJava)

set(CMAKE_JAVA_COMPILE_FLAGS
    "-encoding" "UTF-8"
)

file(GLOB SOURCES ${JAVA_SRC_PATH}/*.java)

add_jar(java_glue
    ${SOURCES}
    INCLUDE_JARS ${PLATFORMS}/android-${TARGET_SDK}/android.jar
)

add_custom_command(
    OUTPUT ${BUILD_INTERMEDIATES_PATH}/classes.dex
    COMMAND ${BUILD_TOOLS}/d8.bat
            java_glue.jar
            --output ${BUILD_INTERMEDIATES_PATH}
            --lib ${PLATFORMS}/android-${TARGET_SDK}/android.jar
    DEPENDS java_glue.jar
    COMMENT "INFO: Generating the classes.dex..."
)

add_custom_target(main ALL DEPENDS ${BUILD_INTERMEDIATES_PATH}/classes.dex)
