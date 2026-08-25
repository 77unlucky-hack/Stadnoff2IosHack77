TARGET := iphone:clang
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libobjc_debug
libobjc_debug_FILES = Tweak.xm ImGui/imgui.cpp ImGui/imgui_draw.cpp ImGui/imgui_widgets.cpp ImGui/imgui_tables.cpp ImGui/imgui_impl_metal.mm
libobjc_debug_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore Metal MetalKit
libobjc_debug_CFLAGS = -fobjc-arc -I./ImGui
libobjc_debug_INSTALL_PATH = @executable_path/Frameworks

include $(THEOS_MAKE_PATH)/library.mk
