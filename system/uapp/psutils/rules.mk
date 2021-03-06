# Copyright 2017 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

LOCAL_DIR := $(GET_LOCAL_DIR)

MODULE := ps

MODULE_TYPE := userapp

MODULE_SRCS += $(LOCAL_DIR)/ps.c $(LOCAL_DIR)/processes.c

MODULE_NAME := ps

MODULE_LIBS := ulib/mxio ulib/magenta ulib/musl

include make/module.mk

MODULE := kill

MODULE_TYPE := userapp

MODULE_SRCS += $(LOCAL_DIR)/kill.c $(LOCAL_DIR)/processes.c

MODULE_NAME := kill

MODULE_LIBS := ulib/mxio ulib/magenta ulib/musl

include make/module.mk

MODULE := killall

MODULE_TYPE := userapp

MODULE_SRCS += $(LOCAL_DIR)/killall.c $(LOCAL_DIR)/processes.c

MODULE_NAME := killall

MODULE_LIBS := ulib/mxio ulib/magenta ulib/musl

include make/module.mk

