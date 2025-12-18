#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <memory>
#include <cmath>

#include "../include/Model.h"
#include "../include/Shader.h"
#include "../include/Camera.h"

// Window dimensions
const GLuint WIDTH = 1024, HEIGHT = 768;

// Orbit Camera
Camera camera(glm::vec3(0.0f, 0.0f, 0.5f));
glm::vec3 cameraTarget = glm::vec3(0.0f, 0.0f, 0.0f);
float cameraYaw = 90.0f;
float cameraPitch = 0.0f;
float cameraRadius = 0.5f;
float minRadius = 0.2f;
float maxRadius = 2.0f;
float orbitRotateSpeed = 60.0f;
float orbitZoomSpeed = 1.0f;
float minOrbitPitch = -80.0f;
float maxOrbitPitch = 80.0f;

// Mouse control
float lastX = WIDTH / 2.0;
float lastY = HEIGHT / 2.0;
bool firstMouse = true;

// Frame time
float deltaTime = 0.0f;
float lastFrame = 0.0f;

// Function to update camera position based on orbit
void updateCameraPosition() {
    float yawRad = glm::radians(cameraYaw);
    float pitchRad = glm::radians(cameraPitch);
    float cosPitch = cos(pitchRad);
    
    glm::vec3 newPos;
    newPos.x = cameraTarget.x + cameraRadius * cosPitch * cos(yawRad);
    newPos.y = cameraTarget.y + cameraRadius * sin(pitchRad);
    newPos.z = cameraTarget.z + cameraRadius * cosPitch * sin(yawRad);
    
    camera.Position = newPos;
    camera.Front = glm::normalize(cameraTarget - newPos);
    camera.Right = glm::normalize(glm::cross(camera.Front, glm::vec3(0.0f, 1.0f, 0.0f)));
    camera.Up = glm::normalize(glm::cross(camera.Right, camera.Front));
}

// Function prototypes
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void mouse_callback(GLFWwindow* window, double xpos, double ypos);
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
void processInput(GLFWwindow *window);

int main()
{
    // Init GLFW
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    // Create window
    GLFWwindow* window = glfwCreateWindow(WIDTH, HEIGHT, "Nail Manicure GL", nullptr, nullptr);
    if (!window)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);

    // Set callbacks
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetScrollCallback(window, scroll_callback);

    // Enable VSync to limit frame rate
    glfwSwapInterval(1);

    // Capture mouse (disabled for easier navigation)
    // glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

    // Init GLEW
    if (glewInit() != GLEW_OK)
    {
        std::cout << "Failed to initialize GLEW" << std::endl;
        return -1;
    }

    // Configure OpenGL state
    glEnable(GL_DEPTH_TEST);

    // Build and compile shaders (with geometry shader)
    Shader manicureShader("../shaders/manicure.vs", "../shaders/manicure.fs", "../shaders/manicure.geom");
    
    // Load hand model
    Model handModel("../hand.obj");

    // Initialize camera position
    updateCameraPosition();

    // Render loop
    while (!glfwWindowShouldClose(window))
    {
        // Per-frame time logic
        float currentFrame = glfwGetTime();
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        // Input
        processInput(window);

        // Clear screen
        glClearColor(0.8f, 0.8f, 0.9f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Use shader
        manicureShader.use();
        
        // Pass time to shader
        manicureShader.setFloat("time", currentFrame);
        manicureShader.setInt("isNail", 1);  // Enable nail decoration
        
        // Lighting
        glm::vec3 lightPos(0.5f, 0.5f, 1.0f);
        manicureShader.setVec3("lightPos", lightPos);
        manicureShader.setVec3("viewPos", camera.Position);
        
        // View/projection transformations
        glm::mat4 projection = glm::perspective(glm::radians(camera.Zoom), (float)WIDTH / (float)HEIGHT, 0.1f, 100.0f);
        glm::mat4 view = camera.GetViewMatrix();
        manicureShader.setMat4("projection", projection);
        manicureShader.setMat4("view", view);

        // Model transformation
        glm::mat4 model = glm::mat4(1.0f);
        model = glm::scale(model, glm::vec3(5.0f, 5.0f, 5.0f));  // Scale up the model
        model = glm::translate(model, glm::vec3(0.0f, -0.05f, 0.0f));  // Center the model
        manicureShader.setMat4("model", model);

        // Render hand model
        handModel.Draw(manicureShader);

        // Swap buffers and poll IO events
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}

void processInput(GLFWwindow *window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);

    float yawDelta = 0.0f;
    float pitchDelta = 0.0f;
    float radiusDelta = 0.0f;

    // A/D: rotate left/right (yaw)
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        yawDelta += orbitRotateSpeed * deltaTime;
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        yawDelta -= orbitRotateSpeed * deltaTime;
    
    // Space/Shift: rotate up/down (pitch)
    if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS)
        pitchDelta += orbitRotateSpeed * deltaTime;
    if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS)
        pitchDelta -= orbitRotateSpeed * deltaTime;
    
    // W/S: zoom in/out
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        radiusDelta -= orbitZoomSpeed * deltaTime;
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        radiusDelta += orbitZoomSpeed * deltaTime;

    // Apply changes
    if (yawDelta != 0.0f || pitchDelta != 0.0f || radiusDelta != 0.0f) {
        cameraYaw += yawDelta;
        cameraPitch = glm::clamp(cameraPitch + pitchDelta, minOrbitPitch, maxOrbitPitch);
        cameraRadius = glm::clamp(cameraRadius + radiusDelta, minRadius, maxRadius);
        updateCameraPosition();
    }
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
}

void mouse_callback(GLFWwindow* window, double xpos, double ypos)
{
    // Only process mouse movement when left button is pressed
    if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) != GLFW_PRESS)
    {
        firstMouse = true;
        return;
    }

    if (firstMouse)
    {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }

    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos;

    lastX = xpos;
    lastY = ypos;

    // Apply mouse movement to orbit camera
    float sensitivity = 0.1f;
    cameraYaw += xoffset * sensitivity;
    cameraPitch = glm::clamp(cameraPitch + yoffset * sensitivity, minOrbitPitch, maxOrbitPitch);
    updateCameraPosition();
}

void scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
{
    // Use scroll for zooming
    cameraRadius -= yoffset * 0.05f;
    cameraRadius = glm::clamp(cameraRadius, minRadius, maxRadius);
    updateCameraPosition();
}