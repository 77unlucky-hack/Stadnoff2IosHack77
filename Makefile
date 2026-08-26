TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Standoff2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Lucky77
Lucky77_FILES = Tweak.xm
Lucky77_CFLAGS = -fobjc-arc
Lucky77_FRAMEWORKS = UIKit AudioToolbox QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
