TARGET := iphone:clang:latest:15.0
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = Lucky77
Lucky77_FILES = Tweak.xm
Lucky77_CFLAGS = -fobjc-arc -dynamiclib
Lucky77_LDFLAGS = -dynamiclib
Lucky77_FRAMEWORKS = UIKit AudioToolbox QuartzCore
Lucky77_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/tool.mk
