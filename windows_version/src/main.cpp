#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <iostream>
#include <vector>
#include <fstream>
#include <sstream>

#include "./header/Object.h"
#include "./header/stb_image.h"

using namespace std;

// 函式預告
void framebufferSizeCallback(GLFWwindow *window, int width, int height);
void keyCallback(GLFWwindow *window, int key, int scancode, int action, int mods);
void mouseButtonCallback(GLFWwindow* window, int button, int action, int mods);
void cursorPosCallback(GLFWwindow* window, double xpos, double ypos);
void scrollCallback(GLFWwindow* window, double xoffset, double yoffset);
unsigned int createShader(const string &filename, const string &type);
unsigned int createProgram(unsigned int vertexShader, unsigned int fragmentShader, unsigned int geometryShader);
unsigned int modelVAO(Object &model);
unsigned int loadTexture(const string &filename);

// 全域變數
int SCR_WIDTH = 800;
int SCR_HEIGHT = 600;
unsigned int shaderProgram;
unsigned int handVAO, handTexture;
Object *handObject;
int fingerPainted[6] = { 0,0,0,0,0,0 };
glm::vec3 currentCameraTarget(0.0f, 0.0f, 0.0f);

// 狀態變數
int activeFinger = 0;      // 0:全手, 1-5 對應 a-e
bool isGrowing = false;
float patternProgress = 0.0f;

// 相機控制變數
float cameraDistance = 10.0f;
float cameraYaw = 0.0f;     // 左右旋轉
float cameraPitch = 45.0f;  // 上下旋轉
bool isRotating = false;
double lastMouseX = 0.0;
double lastMouseY = 0.0;

void init() {
#if defined(__linux__) || defined(__APPLE__)
    string dirShader = "../../src/shaders/";
    string dirAsset = "../../src/asset/obj/";
    string dirTexture = "../../src/asset/texture/";
#else
    string dirShader = "..\\..\\src\\shaders\\";
    string dirAsset = "..\\..\\src\\asset\\obj\\";
    string dirTexture = "..\\..\\src\\asset\\texture\\";
#endif

    cout << "Loading hand object..." << endl;
    handObject = new Object(dirAsset + "female_hand.obj"); 
    
    cout << "Compiling shaders..." << endl;
    unsigned int vs = createShader(dirShader + "vertexShader.vert", "vert");
    unsigned int fs = createShader(dirShader + "fragmentShader.frag", "frag");
    unsigned int gs = createShader(dirShader + "geometryShader.geom", "geom");
    shaderProgram = createProgram(vs, fs, gs);

    cout << "Creating VAO..." << endl;
    handVAO = modelVAO(*handObject);
    
    cout << "Loading texture..." << endl;
    handTexture = loadTexture(dirTexture + "female_hand.png");
    
    cout << "Initialization complete!" << endl;
}

int main() {
    if (!glfwInit()) return -1;
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow *window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "HW2 - Hand Decoration", NULL, NULL);
    if (!window) { 
        cout << "Failed to create window" << endl;
        glfwTerminate(); 
        return -1; 
    }
    
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    glfwSetKeyCallback(window, keyCallback);
    glfwSetMouseButtonCallback(window, mouseButtonCallback);
    glfwSetCursorPosCallback(window, cursorPosCallback);
    glfwSetScrollCallback(window, scrollCallback);
    
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        cout << "Failed to initialize GLAD" << endl;
        return -1;
    }

    init();
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    cout << "\n=== Controls ===" << endl;
    cout << "A/B/C/D/E: Select finger (thumb/index/middle/ring/pinky)" << endl;
    cout << "S: Start decoration (when finger selected)" << endl;
    cout << "Left Mouse + Drag: Rotate camera" << endl;
    cout << "Mouse Wheel: Zoom in/out" << endl;
    cout << "ESC: Exit" << endl;

    while (!glfwWindowShouldClose(window)) {
        float currentTime = (float)glfwGetTime();
        glClearColor(0.15f, 0.15f, 0.18f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glUseProgram(shaderProgram);

        // 1. 更新花紋生長進度
        if (isGrowing) {
            patternProgress += 0.005f; // 調慢進度，讓漸變更自然
            if (patternProgress > 1.0f) {
                isGrowing = false;
                fingerPainted[activeFinger] = 1; // 記錄此手指已完成
                patternProgress = 0.0f;
                // 完成後不強制切換 activeFinger，讓使用者看清楚
            }
        }

        // 2. 計算動態相機目標 (平滑過渡)
        glm::vec3 targetPos(0.0f, 0.0f, 0.0f);
        float targetDist = 10.0f;

        if (activeFinger > 0) {
            // 根據手指位置微調看點 (此處座標請依模型實際位置微調)
            float fingerX = (activeFinger - 3) * 0.7f; 
            targetPos = glm::vec3(fingerX, 0.5f, 0.0f);
            targetDist = 4.0f; 
        }

        // 平滑差值 (Lerp)
        static glm::vec3 currentCameraTarget(0.0f); // 靜態變數保留上次狀態
        currentCameraTarget = glm::mix(currentCameraTarget, targetPos, 0.05f);
        cameraDistance = glm::mix(cameraDistance, targetDist, 0.05f);

        // 3. 計算相機位置與矩陣
        float camX = cameraDistance * cos(glm::radians(cameraPitch)) * sin(glm::radians(cameraYaw));
        float camY = cameraDistance * sin(glm::radians(cameraPitch));
        float camZ = cameraDistance * cos(glm::radians(cameraPitch)) * cos(glm::radians(cameraYaw));
        
        glm::vec3 cameraPos = glm::vec3(camX, camY, camZ);
        glm::vec3 cameraUp = glm::vec3(0.0f, 1.0f, 0.0f);

        glm::mat4 projection = glm::perspective(glm::radians(45.0f), (float)SCR_WIDTH / SCR_HEIGHT, 0.1f, 1000.0f);
        glm::mat4 view = glm::lookAt(cameraPos, currentCameraTarget, cameraUp);
        
        glm::mat4 model = glm::mat4(1.0f);
        model = glm::translate(model, glm::vec3(0.0f, -1.5f, 0.0f));
        model = glm::rotate(model, glm::radians(-45.0f), glm::vec3(1, 0, 0));
        model = glm::scale(model, glm::vec3(0.6f, 0.6f, 0.6f));

        // 4. 傳遞 Uniform
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "model"), 1, GL_FALSE, glm::value_ptr(model));
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "view"), 1, GL_FALSE, glm::value_ptr(view));
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "projection"), 1, GL_FALSE, glm::value_ptr(projection));

        glUniform1i(glGetUniformLocation(shaderProgram, "activeFinger"), activeFinger);
        glUniform1f(glGetUniformLocation(shaderProgram, "patternProgress"), patternProgress);
        glUniform1i(glGetUniformLocation(shaderProgram, "showPattern"), isGrowing ? 1 : 0);
        glUniform1iv(glGetUniformLocation(shaderProgram, "fingerPainted"), 6, fingerPainted);

        // 5. 繪製
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, handTexture);
        glUniform1i(glGetUniformLocation(shaderProgram, "handTexture"), 0);

        glBindVertexArray(handVAO);
        glDrawArrays(GL_TRIANGLES, 0, (GLsizei)handObject->positions.size() / 3);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}

void keyCallback(GLFWwindow *window, int key, int scancode, int action, int mods) {
    if (action == GLFW_PRESS) {
        switch (key) {
            case GLFW_KEY_A: 
                activeFinger = 1; 
                cout << "Selected: Thumb" << endl;
                break;
            case GLFW_KEY_B: 
                activeFinger = 2; 
                cout << "Selected: Index finger" << endl;
                break;
            case GLFW_KEY_C: 
                activeFinger = 3; 
                cout << "Selected: Middle finger" << endl;
                break;
            case GLFW_KEY_D: 
                activeFinger = 4; 
                cout << "Selected: Ring finger" << endl;
                break;
            case GLFW_KEY_E: 
                activeFinger = 5; 
                cout << "Selected: Pinky" << endl;
                break;
            case GLFW_KEY_S: 
                if (activeFinger != 0 && !isGrowing) {
                    isGrowing = true;
                    patternProgress = 0.0f;
                    cout << "Growing decoration on finger " << activeFinger << "..." << endl;
                }
                break;
            case GLFW_KEY_ESCAPE: 
                glfwSetWindowShouldClose(window, true); 
                break;
            case GLFW_KEY_SPACE: // 按下空白鍵回到全手視角
                activeFinger = 0;
                isGrowing = false;
                cout << "Returning to full view..." << endl;
                break;
        }
    }
}

void mouseButtonCallback(GLFWwindow* window, int button, int action, int mods) {
    if (button == GLFW_MOUSE_BUTTON_LEFT) {
        if (action == GLFW_PRESS) {
            isRotating = true;
            glfwGetCursorPos(window, &lastMouseX, &lastMouseY);
        } else if (action == GLFW_RELEASE) {
            isRotating = false;
        }
    }
}

void cursorPosCallback(GLFWwindow* window, double xpos, double ypos) {
    if (isRotating) {
        double deltaX = xpos - lastMouseX;
        double deltaY = ypos - lastMouseY;
        
        cameraYaw += deltaX * 0.5f;
        cameraPitch += deltaY * 0.5f;
        
        // 限制俯仰角
        if (cameraPitch > 89.0f) cameraPitch = 89.0f;
        if (cameraPitch < -89.0f) cameraPitch = -89.0f;
        
        lastMouseX = xpos;
        lastMouseY = ypos;
    }
}

void scrollCallback(GLFWwindow* window, double xoffset, double yoffset) {
    cameraDistance -= yoffset * 0.5f;
    
    // 限制縮放範圍
    if (cameraDistance < 3.0f) cameraDistance = 3.0f;
    if (cameraDistance > 30.0f) cameraDistance = 30.0f;
}

unsigned int createShader(const string &filename, const string &type) {
    ifstream f(filename);
    if (!f.is_open()) {
        cout << "Failed to open shader: " << filename << endl;
        return 0;
    }
    
    stringstream ss;
    ss << f.rdbuf();
    string code = ss.str();
    const char* src = code.c_str();

    GLenum shaderType;
    if (type == "vert") shaderType = GL_VERTEX_SHADER;
    else if (type == "geom") shaderType = GL_GEOMETRY_SHADER;
    else shaderType = GL_FRAGMENT_SHADER;

    unsigned int shader = glCreateShader(shaderType);
    glShaderSource(shader, 1, &src, NULL);
    glCompileShader(shader);

    int success;
    char infoLog[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        cout << "Shader compile error (" << type << "): " << infoLog << endl;
        return 0;
    }
    
    cout << "Shader compiled: " << type << endl;
    return shader;
}

unsigned int createProgram(unsigned int vs, unsigned int gs, unsigned int fs) {
    unsigned int prog = glCreateProgram();

    glAttachShader(prog, vs);
    glAttachShader(prog, gs);
    glAttachShader(prog, fs);

    glLinkProgram(prog);

    int success;
    char infoLog[512];
    glGetProgramiv(prog, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(prog, 512, NULL, infoLog);
        cout << "Program link error: " << infoLog << endl;
        return 0;
    }

    glDeleteShader(vs);
    glDeleteShader(gs);
    glDeleteShader(fs);
    
    cout << "Program linked successfully" << endl;
    return prog;
}

unsigned int modelVAO(Object &model) {
    unsigned int VAO, VBO[3];
    glGenVertexArrays(1, &VAO);
    glGenBuffers(3, VBO);
    glBindVertexArray(VAO);
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, VBO[0]);
    glBufferData(GL_ARRAY_BUFFER, model.positions.size() * sizeof(float), 
                 &model.positions[0], GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    // Normal (if exists)
    if (!model.normals.empty()) {
        glBindBuffer(GL_ARRAY_BUFFER, VBO[1]);
        glBufferData(GL_ARRAY_BUFFER, model.normals.size() * sizeof(float), 
                     &model.normals[0], GL_STATIC_DRAW);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
        glEnableVertexAttribArray(1);
    }
    
    // TexCoord
    glBindBuffer(GL_ARRAY_BUFFER, VBO[2]);
    glBufferData(GL_ARRAY_BUFFER, model.texcoords.size() * sizeof(float), 
                 &model.texcoords[0], GL_STATIC_DRAW);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(2);
    
    cout << "VAO created with " << model.positions.size()/3 << " vertices" << endl;
    return VAO;
}

unsigned int loadTexture(const string &filename) {
    unsigned int textureID;
    glGenTextures(1, &textureID);
    
    int width, height, nrComponents;
    stbi_set_flip_vertically_on_load(true);
    unsigned char *data = stbi_load(filename.c_str(), &width, &height, &nrComponents, 0);
    
    if (data) {
        GLenum format = (nrComponents == 4) ? GL_RGBA : GL_RGB;
        glBindTexture(GL_TEXTURE_2D, textureID);
        glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        cout << "Texture loaded: " << width << "x" << height << " (" << nrComponents << " channels)" << endl;
        stbi_image_free(data);
    } else {
        cout << "Failed to load texture: " << filename << endl;
    }
    
    return textureID;
}

void framebufferSizeCallback(GLFWwindow *window, int width, int height) {
    glViewport(0, 0, width, height);
    SCR_WIDTH = width; 
    SCR_HEIGHT = height;
}