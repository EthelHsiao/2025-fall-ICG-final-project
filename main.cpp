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
string resolveBase(const vector<string> &bases, const string &probeFile);

// 全域變數
int SCR_WIDTH = 800;
int SCR_HEIGHT = 600;
unsigned int shaderProgram;
unsigned int handVAO, handTexture;
Object *handObject;
int fingerPainted[6] = { 0,0,0,0,0,0 };

// ★ 修改：相機目標控制變數 (全域)
// 設定初始值為兩手的中心點 (X: -5.2, Y: 0.8)
glm::vec3 currentCameraTarget(0.0f, 0.0f, 0.0f); 
glm::vec3 targetPos(0.0f, 0.0f, 0.0f);           
float targetDist = 13.0f;                         // 預設距離
float targetYaw = 0.0f; 
float targetPitch = 135.0f;
int lastActiveFinger = -1;

// 狀態變數
int activeFinger = 0;      // 0:全手, 1-5 對應 a-e
bool isGrowing = false;
float patternProgress = 0.0f;
bool celebrateSpin = false;   // 全部完成後的旋轉動畫開關
float celebrateAngle = 0.0f;  // 旋轉角度累積

// 相機實際變數
float cameraDistance = 13.0f;
float cameraYaw = 0.0f;
float cameraPitch = 135.0f;
bool isRotating = false;
double lastMouseX = 0.0;
double lastMouseY = 0.0;

string resolveBase(const vector<string> &bases, const string &probeFile) {
    for (const auto &base : bases) {
        ifstream f(base + probeFile);
        if (f.good()) {
            return base;
        }
    }
    cout << "[WARN] Falling back to first base path: " << bases.front() << endl;
    return bases.front();
}

void init() {
    vector<string> shaderBases = { "../../src/shaders/", "../src/shaders/", "src/shaders/" };
    vector<string> assetBases = { "../../src/asset/obj/", "../src/asset/obj/", "src/asset/obj/" };
    vector<string> textureBases = { "../../src/asset/texture/", "../src/asset/texture/", "src/asset/texture/" };

    string dirShader = resolveBase(shaderBases, "vertexShader.vert");
    string dirAsset = resolveBase(assetBases, "female_hand.obj");
    string dirTexture = resolveBase(textureBases, "female_hand.png");

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
    glDisable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    cout << "\n=== Controls ===" << endl;
    cout << "A/B/C/D/E: Select finger (thumb/index/middle/ring/pinky)" << endl;
    cout << "S: Start decoration (when finger selected)" << endl;
    cout << "Left Mouse + Drag: Rotate camera" << endl;
    cout << "Mouse Wheel: Zoom in/out" << endl;
    cout << "Space: Reset View (Center)" << endl;
    cout << "Arrow Keys: Move Camera" << endl;
    cout << "ESC: Exit" << endl;

    while (!glfwWindowShouldClose(window)) {
        float currentTime = (float)glfwGetTime();
        glClearColor(0.15f, 0.15f, 0.18f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glUseProgram(shaderProgram);

        // 1. 更新花紋生長進度
        if (isGrowing) {
            patternProgress += 0.005f; 
            if (patternProgress > 1.0f) {
                isGrowing = false;
                fingerPainted[activeFinger] = 1;
                patternProgress = 0.0f;
            }
        }

        // 1-5 全部完成後啟動旋轉展示（持續迴圈，回到初始姿態再轉）
        if (fingerPainted[1] && fingerPainted[2] && fingerPainted[3] && fingerPainted[4] && fingerPainted[5]) {
            if (!celebrateSpin) {
                celebrateSpin = true;
                celebrateAngle = 0.0f;
                cout << "All fingers finished! Celebrating spin..." << endl;
            }
        }

        // 更新旋轉動畫角度，較慢速度並循環，確保每圈回到初始姿態
        if (celebrateSpin) {
            celebrateAngle += 0.6f; // 放慢旋轉速度
            if (celebrateAngle >= 360.0f) {
                celebrateAngle -= 360.0f; // 回到初始角度，繼續下一圈
            }
        }

        // 2. 判斷是否切換了手指
        if (activeFinger != lastActiveFinger) {
            if (activeFinger > 0) {
                switch(activeFinger) {
                    case 1: targetPos = glm::vec3(-1.0f, -1.5f, 0.0f); targetDist = 1.5f; break;
                    case 2: targetPos = glm::vec3(-3.0f, 3.0f, 0.0f); targetDist = 1.5f; break;
                    case 3: targetPos = glm::vec3(-4.5f, 3.0f, 0.0f); targetDist = 1.5f; break;
                    case 4: targetPos = glm::vec3(-6.0f, 3.0f, 0.0f); targetDist = 1.5f; break;
                    case 5: targetPos = glm::vec3(-7.2f, 1.2f, 0.0f); targetDist = 1.5f; break;
                }
            } else {
                // 自動切回全手時的預設位置 (與初始值相同)
                targetPos = glm::vec3(0.0f, 0.0f, 0.0f); 
                targetDist = 13.0f;
                targetYaw = 0.0f;
                targetPitch = 135.0f;
            }
            lastActiveFinger = activeFinger;
        }

        // 3. 平滑差值
        currentCameraTarget = glm::mix(currentCameraTarget, targetPos, 0.05f);
        cameraDistance = glm::mix(cameraDistance, targetDist, 0.05f);
        cameraYaw = glm::mix(cameraYaw, targetYaw, 0.05f);
        cameraPitch = glm::mix(cameraPitch, targetPitch, 0.05f);

        // 4. 計算相機位置與矩陣
        float camX = cameraDistance * cos(glm::radians(cameraPitch)) * sin(glm::radians(cameraYaw));
        float camY = cameraDistance * sin(glm::radians(cameraPitch));
        float camZ = cameraDistance * cos(glm::radians(cameraPitch)) * cos(glm::radians(cameraYaw));

        glm::vec3 cameraPos = currentCameraTarget + glm::vec3(camX, camY, camZ);
        glm::vec3 cameraUp = glm::vec3(0.0f, 1.0f, 0.0f);

        glm::mat4 projection = glm::perspective(glm::radians(45.0f), (float)SCR_WIDTH / SCR_HEIGHT, 0.1f, 1000.0f);
        glm::mat4 view = glm::lookAt(cameraPos, currentCameraTarget, cameraUp);
        glm::mat4 model = glm::mat4(1.0f);
        model = glm::translate(model, glm::vec3(0.0f, -1.5f, 0.0f));
        model = glm::rotate(model, glm::radians(-45.0f), glm::vec3(1, 0, 0));
        if (celebrateSpin) {
            model = glm::rotate(model, glm::radians(celebrateAngle), glm::vec3(0, 1, 0));
        }
        model = glm::scale(model, glm::vec3(0.5f, 0.5f, 0.5f));

        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "model"), 1, GL_FALSE, glm::value_ptr(model));
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "view"), 1, GL_FALSE, glm::value_ptr(view));
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "projection"), 1, GL_FALSE, glm::value_ptr(projection));

        glUniform1i(glGetUniformLocation(shaderProgram, "activeFinger"), activeFinger);
        glUniform1f(glGetUniformLocation(shaderProgram, "patternProgress"), patternProgress);
        glUniform1f(glGetUniformLocation(shaderProgram, "time"), currentTime);
        glUniform1i(glGetUniformLocation(shaderProgram, "showPattern"), 1);
        glUniform1iv(glGetUniformLocation(shaderProgram, "fingerPainted"), 6, fingerPainted);

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
    if (action == GLFW_PRESS || action == GLFW_REPEAT) {
        float moveSpeed = 0.2f; 
        
        switch (key) {
            // 方向鍵控制
            case GLFW_KEY_RIGHT: targetPos.x -= moveSpeed; break;
            case GLFW_KEY_LEFT:  targetPos.x += moveSpeed; break;
            case GLFW_KEY_UP:    targetPos.y += moveSpeed; break;
            case GLFW_KEY_DOWN:  targetPos.y -= moveSpeed; break;

            case GLFW_KEY_A: activeFinger = 1; isGrowing = false; patternProgress = 0.0f; cout << "Selected: Thumb" << endl; break;
            case GLFW_KEY_B: activeFinger = 2; isGrowing = false; patternProgress = 0.0f; cout << "Selected: Index" << endl; break;
            case GLFW_KEY_C: activeFinger = 3; isGrowing = false; patternProgress = 0.0f; cout << "Selected: Middle" << endl; break;
            case GLFW_KEY_D: activeFinger = 4; isGrowing = false; patternProgress = 0.0f; cout << "Selected: Ring" << endl; break;
            case GLFW_KEY_E: activeFinger = 5; isGrowing = false; patternProgress = 0.0f; cout << "Selected: Pinky" << endl; break;
            
            case GLFW_KEY_S: 
                if (activeFinger != 0 && fingerPainted[activeFinger] == 0) {
                    isGrowing = true;
                    patternProgress = 0.01f;
                    cout << "Start Animation!" << endl;
                }
                break;

            case GLFW_KEY_ESCAPE: 
                glfwSetWindowShouldClose(window, true); 
                break;

            // ★ 加回空白鍵：重置回正中間 (-5.2, 0.8)
            case GLFW_KEY_SPACE: 
                activeFinger = 0;
                isGrowing = false;
                
                targetPos = glm::vec3(0.0f, 0.0f, 0.0f); 
                targetDist = 13.0f;
                targetYaw = 0.0f;
                targetPitch = 135.0f;
                
                cout << "Reset View to Center..." << endl;
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
        
        targetYaw += deltaX * 0.5f;
        targetPitch += deltaY * 0.5f;
        
        if (targetPitch > 89.0f) targetPitch = 89.0f;
        if (targetPitch < -89.0f) targetPitch = -89.0f;
        
        lastMouseX = xpos;
        lastMouseY = ypos;
    }
}

void scrollCallback(GLFWwindow* window, double xoffset, double yoffset) {
    targetDist -= yoffset * 0.5f;
    if (targetDist < 1.0f) targetDist = 1.0f; 
}

void framebufferSizeCallback(GLFWwindow *window, int width, int height) {
    glViewport(0, 0, width, height);
    SCR_WIDTH = width;
    SCR_HEIGHT = height;
}

// Shader helper functions... (保持原本的不變)
unsigned int createShader(const string &filename, const string &type) {
    ifstream f(filename);
    if (!f.is_open()) { cout << "Failed to open shader: " << filename << endl; return 0; }
    stringstream ss; ss << f.rdbuf(); string code = ss.str(); const char* src = code.c_str();
    GLenum shaderType; if (type == "vert") shaderType = GL_VERTEX_SHADER; else if (type == "geom") shaderType = GL_GEOMETRY_SHADER; else shaderType = GL_FRAGMENT_SHADER;
    unsigned int shader = glCreateShader(shaderType); glShaderSource(shader, 1, &src, NULL); glCompileShader(shader);
    int success; glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) { char infoLog[512]; glGetShaderInfoLog(shader, 512, NULL, infoLog); cout << "Shader compile error (" << type << "): " << infoLog << endl; return 0; }
    return shader;
}
unsigned int createProgram(unsigned int vs, unsigned int gs, unsigned int fs) {
    unsigned int prog = glCreateProgram(); glAttachShader(prog, vs); glAttachShader(prog, gs); glAttachShader(prog, fs); glLinkProgram(prog);
    int success; glGetProgramiv(prog, GL_LINK_STATUS, &success);
    if (!success) { char infoLog[512]; glGetProgramInfoLog(prog, 512, NULL, infoLog); cout << "Program link error: " << infoLog << endl; return 0; }
    glDeleteShader(vs); glDeleteShader(gs); glDeleteShader(fs); return prog;
}
unsigned int modelVAO(Object &model) {
    unsigned int VAO, VBO[3]; glGenVertexArrays(1, &VAO); glGenBuffers(3, VBO); glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO[0]); glBufferData(GL_ARRAY_BUFFER, model.positions.size() * sizeof(float), &model.positions[0], GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0); glEnableVertexAttribArray(0);
    if (!model.normals.empty()) { glBindBuffer(GL_ARRAY_BUFFER, VBO[1]); glBufferData(GL_ARRAY_BUFFER, model.normals.size() * sizeof(float), &model.normals[0], GL_STATIC_DRAW); glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0); glEnableVertexAttribArray(1); }
    glBindBuffer(GL_ARRAY_BUFFER, VBO[2]); glBufferData(GL_ARRAY_BUFFER, model.texcoords.size() * sizeof(float), &model.texcoords[0], GL_STATIC_DRAW);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0); glEnableVertexAttribArray(2);
    return VAO;
}
unsigned int loadTexture(const string &filename) {
    unsigned int textureID; glGenTextures(1, &textureID);
    int width, height, nrComponents; stbi_set_flip_vertically_on_load(true);
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
        stbi_image_free(data);
    } else { cout << "Failed to load texture: " << filename << endl; }
    return textureID;
}