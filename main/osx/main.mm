// dear imgui: standalone example application for OSX + OpenGL2, using legacy fixed pipeline
// If you are new to dear imgui, see examples/README.txt and documentation at the top of imgui.cpp.

#include <imgui.h>
#include "imgui_impl_osx.h"
#include "imgui_impl_opengl2.h"
#include <stdio.h>
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#include <functional>
#include <app/App.h>

//-----------------------------------------------------------------------------------
// ImGuiExampleView
//-----------------------------------------------------------------------------------

@interface ImGuiExampleView : NSOpenGLView
{
    NSTimer*    animationTimer;
}
@end

@implementation ImGuiExampleView

-(void)animationTimerFired:(NSTimer*)timer
{
    [self setNeedsDisplay:YES];
}

-(void)prepareOpenGL
{
    [super prepareOpenGL];

#ifndef DEBUG
    GLint swapInterval = 1;
    [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
    if (swapInterval == 0)
        NSLog(@"Error: Cannot set swap interval.");
#endif
}

-(void)updateAndDrawDemoView
{
    // Start the Dear ImGui frame
	ImGui_ImplOpenGL2_NewFrame();
	ImGui_ImplOSX_NewFrame(self);
    ImGui::NewFrame();

    static ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);
    
    app::render();
    
	// Rendering
	ImGui::Render();
	[[self openGLContext] makeCurrentContext];

    ImDrawData* draw_data = ImGui::GetDrawData();
    GLsizei width  = (GLsizei)(draw_data->DisplaySize.x * draw_data->FramebufferScale.x);
    GLsizei height = (GLsizei)(draw_data->DisplaySize.y * draw_data->FramebufferScale.y);
    glViewport(0, 0, width, height);

	glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
	glClear(GL_COLOR_BUFFER_BIT);
	ImGui_ImplOpenGL2_RenderDrawData(draw_data);

    // Present
    [[self openGLContext] flushBuffer];

    if (!animationTimer)
        animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.017 target:self selector:@selector(animationTimerFired:) userInfo:nil repeats:YES];
}

-(void)reshape
{
    [[self openGLContext] update];
    [self updateAndDrawDemoView];
}

-(void)drawRect:(NSRect)bounds
{
    [self updateAndDrawDemoView];
}

-(BOOL)acceptsFirstResponder
{
    return (YES);
}

-(BOOL)becomeFirstResponder
{
    return (YES);
}

-(BOOL)resignFirstResponder
{
    return (YES);
}

-(void)dealloc
{
    animationTimer = nil;
}

// Forward Mouse/Keyboard events to dear imgui OSX back-end. It returns true when imgui is expecting to use the event.
-(void)keyUp:(NSEvent *)event           { ImGui_ImplOSX_HandleEvent(event, self); }
-(void)keyDown:(NSEvent *)event         { ImGui_ImplOSX_HandleEvent(event, self); }
-(void)flagsChanged:(NSEvent *)event    { ImGui_ImplOSX_HandleEvent(event, self); }
-(void)mouseDown:(NSEvent *)event       { ImGui_ImplOSX_HandleEvent(event, self); }
-(void)mouseUp:(NSEvent *)event         { ImGui_ImplOSX_HandleEvent(event, self); }
-(void)mouseMoved:(NSEvent *)event      { ImGui_ImplOSX_HandleEvent(event, self); }
-(void)mouseDragged:(NSEvent *)event    { ImGui_ImplOSX_HandleEvent(event, self); }
-(void)scrollWheel:(NSEvent *)event     { ImGui_ImplOSX_HandleEvent(event, self); }

@end

//-----------------------------------------------------------------------------------
// ImGuiExampleAppDelegate
//-----------------------------------------------------------------------------------

@interface ImGuiExampleAppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, readonly) NSWindow* window;
@end

@implementation ImGuiExampleAppDelegate
@synthesize window = _window;

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

-(NSWindow*)window
{
    if (_window != nil)
        return (_window);

    NSRect viewRect = NSMakeRect(100.0, 100.0, 100.0 + 1280.0, 100 + 720.0);

    _window = [[NSWindow alloc] initWithContentRect:viewRect styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:YES];
    [_window setTitle:@"Dear ImGui OSX+OpenGL2 Example"];
    [_window setAcceptsMouseMovedEvents:YES];
    [_window setOpaque:YES];
    [_window makeKeyAndOrderFront:NSApp];

    return (_window);
}

-(void)setupMenu
{
	NSMenu* mainMenuBar = [[NSMenu alloc] init];
    NSMenu* appMenu;
    NSMenuItem* menuItem;

    appMenu = [[NSMenu alloc] initWithTitle:@"Dear ImGui OSX+OpenGL2 Example"];
    menuItem = [appMenu addItemWithTitle:@"Quit Dear ImGui OSX+OpenGL2 Example" action:@selector(terminate:) keyEquivalent:@"q"];
    [menuItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];

    menuItem = [[NSMenuItem alloc] init];
    [menuItem setSubmenu:appMenu];

    [mainMenuBar addItem:menuItem];

    appMenu = nil;
    [NSApp setMainMenu:mainMenuBar];
}

-(void)dealloc
{
    _window = nil;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Make the application a foreground application (else it won't receive keyboard events)
	ProcessSerialNumber psn = {0, kCurrentProcess};
	TransformProcessType(&psn, kProcessTransformToForegroundApplication);

	// Menu
    [self setupMenu];

    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 32,
        0
    };

    NSOpenGLPixelFormat* format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    ImGuiExampleView* view = [[ImGuiExampleView alloc] initWithFrame:self.window.frame pixelFormat:format];
    format = nil;
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
        [view setWantsBestResolutionOpenGLSurface:YES];
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    [self.window setContentView:view];

    if ([view openGLContext] == nil)
        NSLog(@"No OpenGL Context!");

    app::init();

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    //ImGui::StyleColorsClassic();

    // Setup Platform/Renderer bindings
    ImGui_ImplOSX_Init();
    ImGui_ImplOpenGL2_Init();

    // Load Fonts
    // - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui::PushFont()/PopFont() to select them.
    // - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
    // - If the file cannot be loaded, the function will return NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    // - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
    // - Read 'docs/FONTS.txt' for more instructions and details.
    // - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
    //io.Fonts->AddFontDefault();
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
    //ImFont* font = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, NULL, io.Fonts->GetGlyphRangesJapanese());
    //IM_ASSERT(font != NULL);
}

@end

int main(int argc, const char* argv[])
{
	@autoreleasepool
	{
		NSApp = [NSApplication sharedApplication];
		ImGuiExampleAppDelegate* delegate = [[ImGuiExampleAppDelegate alloc] init];
		[[NSApplication sharedApplication] setDelegate:delegate];
		[NSApp run];
	}
	return NSApplicationMain(argc, argv);
}
