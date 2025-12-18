cmake_minimum_required(VERSION 3.16)
project(NailManicureGL)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find packages
find_package(OpenGL REQUIRED)
find_package(glfw3 REQUIRED)

# Handle GLEW differently on Windows vs Linux
if(WIN32)
    find_package(GLEW REQUIRED)
    set(GLEW_LIBRARIES GLEW::GLEW)
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GLEW REQUIRED glew)
endif()

# Handle Assimp
if(WIN32)
    find_package(assimp REQUIRED)
    set(ASSIMP_LIBRARIES assimp::assimp)
else()
    pkg_check_modules(ASSIMP REQUIRED assimp)
endif()

# Include directories
include_directories(include)
include_directories(${GLEW_INCLUDE_DIRS})
include_directories(${ASSIMP_INCLUDE_DIRS})

# Source files
file(GLOB_RECURSE SOURCES "src/*.cpp" "src/*.hpp" "include/*.h")

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Link libraries
target_link_libraries(${PROJECT_NAME} 
    OpenGL::GL 
    glfw
    ${GLEW_LIBRARIES}
    ${ASSIMP_LIBRARIES}
)

# Link directories
link_directories(${GLEW_LIBRARY_DIRS})
link_directories(${ASSIMP_LIBRARY_DIRS})

# Compiler flags (only for Unix-like systems with pkg-config)
if(NOT WIN32)
    target_compile_options(${PROJECT_NAME} PRIVATE ${GLEW_CFLAGS_OTHER})
    target_compile_options(${PROJECT_NAME} PRIVATE ${ASSIMP_CFLAGS_OTHER})
endif()

# Copy shaders and resources to build directory (optional, for convenience)
file(COPY ${CMAKE_SOURCE_DIR}/shaders DESTINATION ${CMAKE_BINARY_DIR})
if(EXISTS ${CMAKE_SOURCE_DIR}/hand.obj)
    file(COPY ${CMAKE_SOURCE_DIR}/hand.obj DESTINATION ${CMAKE_BINARY_DIR})
endif()
if(EXISTS ${CMAKE_SOURCE_DIR}/hand.mtl)
    file(COPY ${CMAKE_SOURCE_DIR}/hand.mtl DESTINATION ${CMAKE_BINARY_DIR})
endif()
if(EXISTS ${CMAKE_SOURCE_DIR}/textures)
    file(COPY ${CMAKE_SOURCE_DIR}/textures DESTINATION ${CMAKE_BINARY_DIR})
endif()