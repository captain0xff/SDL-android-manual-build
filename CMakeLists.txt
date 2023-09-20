cmake_minimum_required(VERSION 3.22.1)

# Declare the project
project(main)

add_library(main SHARED)

target_sources(main PRIVATE src/main.cpp)

add_subdirectory(SDL)

target_link_libraries(main PUBLIC SDL3::SDL3)
