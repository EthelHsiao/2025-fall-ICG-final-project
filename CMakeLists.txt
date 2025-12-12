cmake_minimum_required(VERSION 3.10)
project(ManicureShader)

set(CMAKE_CXX_STANDARD 17)

# Find necessary packages
find_package(OpenGL REQUIRED)
find_package(glfw3 3.3 REQUIRED)

# Assuming GLM is installed
find_package(glm REQUIRED)

# Assuming Assimp is installed for model loading
find_package(assimp REQUIRED)

# Find GLEW
find_package(GLEW REQUIRED)

# Include directories
include_directories(${OPENGL_INCLUDE_DIRS} ${GLEW_INCLUDE_DIRS})

# Source files
set(SOURCES
    src/main.cpp
)

# Create executable
add_executable(ManicureShader ${SOURCES})

# Link libraries
target_link_libraries(ManicureShader
    ${OPENGL_LIBRARIES}
    glfw
    assimp
    glm::glm
    GLEW::GLEW
)

# Copy shaders and models to build directory (optional but helpful)
file(COPY ${CMAKE_SOURCE_DIR}/shaders DESTINATION ${CMAKE_BINARY_DIR})
file(COPY ${CMAKE_SOURCE_DIR}/models DESTINATION ${CMAKE_BINARY_DIR})
file(COPY ${CMAKE_SOURCE_DIR}/hand_model DESTINATION ${CMAKE_BINARY_DIR})
