#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <string.h>
#import "imgui.h"
#import "imgui_impl_metal.h"

// ==================== НАСТРОЙКИ ====================
static BOOL espEnabled = NO;
static BOOL espBox = NO;
static BOOL espLine = NO;
static BOOL espDistance = NO;
static BOOL espSkeleton = NO;
static BOOL aimEnabled = NO;
static CGFloat aimFOV = 100.0;

// ==================== IL2CPP ====================
static void* (*FindObjectsOfType)(void*) = NULL;
static int (*GetActive)(void*) = NULL;
static void* (*GetTransform)(void*) = NULL;
static void (*GetPosition)(void*, float*) = NULL;
static void* (*GetGameObject)(void*) = NULL;
static void* (*GetMainCamera)(void) = NULL;
static void (*WorldToViewport)(void*, float*, int, float*) = NULL;
static void *aimControllerClass = NULL;

static NSMutableArray *screenPlayers = nil;

static void initIL2CPP() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (!name) continue;
        if (!strstr(name, "StandLeo") && !strstr(name, "Unity") && !strstr(name, "il2cpp") && !strstr(name, "Game") && !strstr(name, "Stand")) continue;
        
        void *handle = dlopen(name, RTLD_NOW);
        if (!handle) continue;
        
        void *domain_get = dlsym(handle, "il2cpp_domain_get");
        if (!domain_get) continue;
        
        void *thread_attach = dlsym(handle, "il2cpp_thread_attach");
        void *string_new = dlsym(handle, "il2cpp_string_new");
        void *get_corlib = dlsym(handle, "il2cpp_get_corlib");
        void *class_from_name = dlsym(handle, "il2cpp_class_from_name");
        void *class_get_method = dlsym(handle, "il2cpp_class_get_method_from_name");
        void *resolve_icall = dlsym(handle, "il2cpp_resolve_icall");
        
        void *domain = ((void*(*)(void))domain_get)();
        ((void*(*)(void*))thread_attach)(domain);
        
        FindObjectsOfType = (void* (*)(void*))((void*(*)(const char*))resolve_icall)("UnityEngine.Object::FindObjectsOfType(System.Type)");
        GetActive = (int (*)(void*))((void*(*)(const char*))resolve_icall)("UnityEngine.GameObject::get_activeInHierarchy()");
        GetTransform = (void* (*)(void*))((void*(*)(const char*))resolve_icall)("UnityEngine.GameObject::get_transform()");
        GetPosition = (void (*)(void*, float*))((void*(*)(const char*))resolve_icall)("UnityEngine.Transform::get_position_Injected(UnityEngine.Vector3&)");
        GetGameObject = (void* (*)(void*))((void*(*)(const char*))resolve_icall)("UnityEngine.Component::get_gameObject()");
        GetMainCamera = (void* (*)(void))((void*(*)(const char*))resolve_icall)("UnityEngine.Camera::get_main()");
        WorldToViewport = (void (*)(void*, float*, int, float*))((void*(*)(const char*))resolve_icall)("UnityEngine.Camera::WorldToViewportPoint_Injected(UnityEngine.Vector3&,UnityEngine.Camera/MonoOrStereoscopicEye,UnityEngine.Vector3&)");
        
        void *corlib = ((void*(*)(void))get_corlib)();
        void *asmClass = ((void*(*)(void*, const char*, const char*))class_from_name)(corlib, "System.Reflection", "Assembly");
        void *loadMethod = ((void*(*)(void*, const char*, int))class_get_method)(asmClass, "Load", 1);
        void *getTypeMethod = ((void*(*)(void*, const char*, int))class_get_method)(asmClass, "GetType", 1);
        
        void *asmCSharp = ((void*(*)(void*))loadMethod)(((void*(*)(const char*))string_new)("Assembly-CSharp"));
        
        if (asmCSharp) {
            aimControllerClass = ((void*(*)(void*, void*))getTypeMethod)(asmCSharp, ((void*(*)(const char*))string_new)("Axlebolt.Standoff.Player.Aim.AimController"));
        }
        
        return;
    }
}

static void updatePlayers() {
    [screenPlayers removeAllObjects];
    if (!FindObjectsOfType || !aimControllerClass || !GetMainCamera || !WorldToViewport) return;
    
    void *camera = GetMainCamera();
    if (!camera) return;
    
    void *arr = FindObjectsOfType(aimControllerClass);
    if (!arr) return;
    
    int count = *(int*)((char*)arr + 0x18);
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    for (int i = 0; i < count && i < 50; i++) {
        void *comp = *(void**)((char*)arr + 0x20 + i*8);
        if (!comp) continue;
        
        void *go = GetGameObject(comp);
        if (!go) continue;
        if (!GetActive(go)) continue;
        
        void *transform = GetTransform(go);
        if (!transform) continue;
        
        float pos[3] = {0};
        GetPosition(transform, pos);
        
        float vp[3] = {0};
        WorldToViewport(camera, pos, 2, vp);
        
        if (vp[2] > 0) {
            CGFloat x = vp[0] * bounds.size.width;
            CGFloat y = bounds.size.height * (1 - vp[1]);
            CGFloat z = vp[2];
            [screenPlayers addObject:@{@"x":@(x), @"y":@(y), @"z":@(z)}];
        }
    }
}

// ==================== ImGui View ====================
@interface ImGuiDrawView : UIViewController <MTKViewDelegate>
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@end

@implementation ImGuiDrawView

- (void)loadView {
    self.device = MTLCreateSystemDefaultDevice();
    self.commandQueue = [self.device newCommandQueue];
    
    MTKView *view = [[MTKView alloc] initWithFrame:[UIScreen mainScreen].bounds device:self.device];
    view.delegate = self;
    view.clearColor = MTLClearColorMake(0, 0, 0, 0);
    view.backgroundColor = [UIColor clearColor];
    self.view = view;
    
    ImGui::CreateContext();
    ImGui_ImplMetal_Init(self.device);
}

- (void)drawInMTKView:(MTKView *)view {
    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize = ImVec2(view.bounds.size.width, view.bounds.size.height);
    
    ImGui_ImplMetal_NewFrame(view.currentRenderPassDescriptor);
    ImGui::NewFrame();
    
    if (espEnabled) {
        ImDrawList *draw = ImGui::GetForegroundDrawList();
        for (NSDictionary *p in screenPlayers) {
            CGFloat x = [p[@"x"] floatValue];
            CGFloat y = [p[@"y"] floatValue];
            CGFloat z = [p[@"z"] floatValue];
            if (z < 1) continue;
            
            if (espBox) {
                draw->AddRect(ImVec2(x-1400/z, y-5000/z), ImVec2(x+1400/z, y), IM_COL32(255,0,0,255));
            }
            if (espLine) {
                draw->AddLine(ImVec2(io.DisplaySize.x/2, io.DisplaySize.y), ImVec2(x, y), IM_COL32(0,255,0,255));
            }
            if (espDistance) {
                char buf[32];
                snprintf(buf, 32, "[%.0fM]", z);
                draw->AddText(ImVec2(x-20, y-30), IM_COL32(255,255,255,255), buf);
            }
        }
    }
    
    ImGui::Begin("Settings", NULL, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Checkbox("ESP", &espEnabled);
    ImGui::Checkbox("Box", &espBox);
    ImGui::Checkbox("Line", &espLine);
    ImGui::Checkbox("Distance", &espDistance);
    ImGui::Checkbox("Skeleton", &espSkeleton);
    ImGui::Checkbox("Aim", &aimEnabled);
    ImGui::SliderFloat("FOV", &aimFOV, 50, 300);
    ImGui::End();
    
    ImGui::Render();
    ImDrawData *drawData = ImGui::GetDrawData();
    
    id<MTLCommandBuffer> cmd = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:view.currentRenderPassDescriptor];
    ImGui_ImplMetal_RenderDrawData(drawData, cmd, enc);
    [enc endEncoding];
    [cmd presentDrawable:view.currentDrawable];
    [cmd commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end

%ctor {
    screenPlayers = [NSMutableArray array];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        @try {
            initIL2CPP();
            
            ImGuiDrawView *vc = [[ImGuiDrawView alloc] init];
            UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
            if (!win) return;
            
            [win.rootViewController addChildViewController:vc];
            [win addSubview:vc.view];
            [win bringSubviewToFront:vc.view];
            
            [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer *t) {
                updatePlayers();
            }];
        } @catch (NSException *e) {}
    });
}
