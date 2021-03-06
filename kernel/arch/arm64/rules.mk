# Copyright 2016 The Fuchsia Authors
# Copyright (c) 2008-2015 Travis Geiselbrecht
#
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT

LOCAL_DIR := $(GET_LOCAL_DIR)

MODULE := $(LOCAL_DIR)

# set some options based on the core
ifeq ($(ARM_CPU),cortex-a53)
ARCH_COMPILEFLAGS += -mcpu=$(ARM_CPU)
else
$(error $(LOCAL_DIR)/rules.mk doesnt have logic for arm core $(ARM_CPU))
endif

MODULE_SRCS += \
	$(LOCAL_DIR)/arch.c \
	$(LOCAL_DIR)/asm.S \
	$(LOCAL_DIR)/cache-ops.S \
	$(LOCAL_DIR)/debugger.c \
	$(LOCAL_DIR)/exceptions.S \
	$(LOCAL_DIR)/exceptions_c.c \
	$(LOCAL_DIR)/fpu.c \
	$(LOCAL_DIR)/hypervisor.cpp \
	$(LOCAL_DIR)/mmu.cpp \
	$(LOCAL_DIR)/platform.c \
	$(LOCAL_DIR)/spinlock.S \
	$(LOCAL_DIR)/start.S \
	$(LOCAL_DIR)/thread.c \
	$(LOCAL_DIR)/user_copy.S \
	$(LOCAL_DIR)/user_copy_c.c \
	$(LOCAL_DIR)/uspace_entry.S

MODULE_DEPS += \
	lib/fdt \

KERNEL_DEFINES += \
	ARM64_CPU_$(ARM_CPU)=1 \
	ARM_ISA_ARMV8=1 \
	ARM_ISA_ARMV8A=1 \
	ARCH_DEFAULT_STACK_SIZE=4096

# if its requested we build with SMP, arm generically supports 4 cpus

SMP_CPU_CLUSTER_SHIFT ?= 8
SMP_CPU_ID_SHIFT ?= 0

ifeq ($(call TOBOOL,$(WITH_SMP)),true)

SMP_CPU_CLUSTER_BITS ?= 2
SMP_CPU_ID_BITS ?= 2
SMP_MAX_CPUS ?= 4
SMP_WITH_SMP ?= 1

MODULE_SRCS += \
    $(LOCAL_DIR)/mp.c

else

SMP_CPU_CLUSTER_BITS ?= 1
SMP_CPU_ID_BITS ?= 1
SMP_MAX_CPUS ?= 1
SMP_WITH_SMP ?= 0

endif

KERNEL_DEFINES += \
    WITH_SMP=$(SMP_WITH_SMP) \
    SMP_MAX_CPUS=$(SMP_MAX_CPUS) \
    SMP_CPU_CLUSTER_BITS=$(SMP_CPU_CLUSTER_BITS) \
    SMP_CPU_CLUSTER_SHIFT=$(SMP_CPU_CLUSTER_SHIFT) \
    SMP_CPU_ID_BITS=$(SMP_CPU_ID_BITS) \
    SMP_CPU_ID_SHIFT=$(SMP_CPU_ID_SHIFT) \

ARCH_OPTFLAGS := -O2

# Turn on -fasynchronous-unwind-tables to get .eh_frame.
# This is necessary for unwinding through optimized code.
GLOBAL_COMPILEFLAGS += -fasynchronous-unwind-tables

KERNEL_ASPACE_BASE ?= 0xffff000000000000
KERNEL_ASPACE_SIZE ?= 0x0001000000000000
USER_ASPACE_BASE   ?= 0x0000000001000000
USER_ASPACE_SIZE   ?= 0x0000fffffe000000

GLOBAL_DEFINES += \
    KERNEL_ASPACE_BASE=$(KERNEL_ASPACE_BASE) \
    KERNEL_ASPACE_SIZE=$(KERNEL_ASPACE_SIZE) \
    USER_ASPACE_BASE=$(USER_ASPACE_BASE) \
    USER_ASPACE_SIZE=$(USER_ASPACE_SIZE)

KERNEL_BASE ?= $(KERNEL_ASPACE_BASE)
KERNEL_LOAD_OFFSET ?= 0

KERNEL_DEFINES += \
    KERNEL_BASE=$(KERNEL_BASE) \
    KERNEL_LOAD_OFFSET=$(KERNEL_LOAD_OFFSET)

KERNEL_DEFINES += \
	MEMBASE=$(MEMBASE) \
	MEMSIZE=$(MEMSIZE)

# try to find the toolchain
include $(LOCAL_DIR)/toolchain.mk
TOOLCHAIN_PREFIX := $(ARCH_$(ARCH)_TOOLCHAIN_PREFIX)

ARCH_COMPILEFLAGS += $(ARCH_$(ARCH)_COMPILEFLAGS)

ifeq ($(call TOBOOL,$(USE_CLANG)),true)
GLOBAL_LDFLAGS += -m aarch64elf
GLOBAL_MODULE_LDFLAGS += -m aarch64elf
endif
GLOBAL_LDFLAGS += -z max-page-size=4096

# kernel hard disables floating point
KERNEL_COMPILEFLAGS += -mgeneral-regs-only
KERNEL_DEFINES += WITH_NO_FP=1

# See engine.mk.
KEEP_FRAME_POINTER_COMPILEFLAGS += -mno-omit-leaf-frame-pointer

ifeq ($(call TOBOOL,$(USE_CLANG)),true)
ifndef ARCH_arm64_CLANG_TARGET
ARCH_arm64_CLANG_TARGET := aarch64-fuchsia
endif
GLOBAL_COMPILEFLAGS += --target=$(ARCH_arm64_CLANG_TARGET)
endif

# make sure some bits were set up
MEMVARS_SET := 0
ifneq ($(MEMBASE),)
MEMVARS_SET := 1
endif
ifneq ($(MEMSIZE),)
MEMVARS_SET := 1
endif
ifeq ($(MEMVARS_SET),0)
$(error missing MEMBASE or MEMSIZE variable, please set in target rules.mk)
endif

# potentially generated files that should be cleaned out with clean make rule
GENERATED += \
	$(BUILDDIR)/system-onesegment.ld

# rules for generating the linker script
$(BUILDDIR)/system-onesegment.ld: $(LOCAL_DIR)/system-onesegment.ld $(wildcard arch/*.ld) linkerscript.phony
	@echo generating $@
	@$(MKDIR)
	$(NOECHO)sed "s/%MEMBASE%/$(MEMBASE)/;s/%MEMSIZE%/$(MEMSIZE)/;s/%KERNEL_BASE%/$(KERNEL_BASE)/;s/%KERNEL_LOAD_OFFSET%/$(KERNEL_LOAD_OFFSET)/" < $< > $@.tmp
	@$(call TESTANDREPLACEFILE,$@.tmp,$@)

linkerscript.phony:
.PHONY: linkerscript.phony

include make/module.mk
