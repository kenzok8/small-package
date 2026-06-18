# SPDX-License-Identifier: GPL-3.0-only
#
# Detached kernel BTF for CO-RE eBPF (dae/daed) on firmware whose kernel was
# built without CONFIG_DEBUG_INFO_BTF. Builds a shadow kernel from the same
# OpenWrt source + .config with BTF enabled, then pahole-encodes a detached
# vmlinux.btf. cilium/ebpf finds it at /usr/lib/debug/boot/vmlinux-<release>.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=vmlinux-btf
PKG_VERSION:=$(LINUX_VERSION)
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

PKG_BUILD_PARALLEL:=1

define Package/vmlinux-btf
  SECTION:=kernel
  CATEGORY:=Kernel
  TITLE:=Kernel vmlinux.btf for CO-RE compatibility
endef

define Package/vmlinux-btf/description
  Supplies detached kernel BTF so CO-RE eBPF programs (dae/daed) load on
  kernels built without CONFIG_DEBUG_INFO_BTF. Builds a shadow kernel from the
  OpenWrt kernel source with BTF enabled and encodes a detached vmlinux.btf.
endef

define Package/vmlinux-btf/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	ln -sf /usr/lib/debug/boot/vmlinux /usr/lib/debug/boot/vmlinux-$$(uname -r)
fi
endef

define Package/vmlinux-btf/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -f /usr/lib/debug/boot/vmlinux-$$(uname -r)
fi
endef

PAHOLE_JOBS := $(if $(filter -j%,$(PKG_JOBS)),$(patsubst -j%,%,$(filter -j%,$(PKG_JOBS))),1)

# The SDK ships an extracted kernel but no dl/ tarball, so fetch vanilla source.
KERNEL_MAJOR:=$(firstword $(subst ., ,$(LINUX_VERSION)))
LINUX_TARBALL_URL:=https://cdn.kernel.org/pub/linux/kernel/v$(KERNEL_MAJOR).x/$(LINUX_SOURCE)

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR) $(DL_DIR)
	[ -f "$(DL_DIR)/$(LINUX_SOURCE)" ] || \
		wget -nv -O "$(DL_DIR)/$(LINUX_SOURCE)" "$(LINUX_TARBALL_URL)"
	$(TAR) -C $(PKG_BUILD_DIR) -xf $(DL_DIR)/$(LINUX_SOURCE)
	mv $(PKG_BUILD_DIR)/linux-$(LINUX_VERSION) $(PKG_BUILD_DIR)/shadow-kernel
	cp $(LINUX_DIR)/.config $(PKG_BUILD_DIR)/shadow-kernel/.config
endef

define Build/Compile
	$(PKG_BUILD_DIR)/shadow-kernel/scripts/config \
		--file $(PKG_BUILD_DIR)/shadow-kernel/.config \
		--disable WERROR \
		--enable CGROUPS \
		--enable CGROUP_BPF \
		--enable SOCK_CGROUP_DATA \
		--enable KALLSYMS \
		--enable PERF_EVENTS \
		--enable TRACEPOINTS \
		--enable KPROBES \
		--enable UPROBES \
		--enable BPF \
		--enable BPF_SYSCALL \
		--enable BPF_JIT \
		--enable BPF_JIT_DEFAULT_ON \
		--enable INET \
		--enable NET_INGRESS \
		--enable NET_EGRESS \
		--enable BPF_STREAM_PARSER \
		--enable XDP_SOCKETS \
		--enable NET_SCHED \
		--enable NET_SCH_INGRESS \
		--enable NET_CLS \
		--enable NET_CLS_ACT \
		--enable KPROBE_EVENTS \
		--enable UPROBE_EVENTS \
		--enable BPF_EVENTS \
		--enable DEBUG_KERNEL \
		--enable DEBUG_INFO \
		--disable DEBUG_INFO_NONE \
		--enable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT \
		--disable DEBUG_INFO_REDUCED \
		--disable DEBUG_INFO_SPLIT \
		--enable DEBUG_INFO_BTF \
		--set-str EXTRA_FIRMWARE "" \
		--set-str INITRAMFS_SOURCE ""

	$(MAKE) -C $(PKG_BUILD_DIR)/shadow-kernel \
		$(KERNEL_MAKE_FLAGS) \
		KBUILD_HOSTLDFLAGS="$(KBUILD_HOSTLDFLAGS) -lz" \
		olddefconfig

	$(MAKE) -C $(PKG_BUILD_DIR)/shadow-kernel \
		$(KERNEL_MAKE_FLAGS) \
		$(PKG_JOBS) \
		KBUILD_HOSTLDFLAGS="-L$(STAGING_DIR_HOST)/lib -lz" \
		vmlinux

	pahole \
		--jobs=$(PAHOLE_JOBS) \
		--btf_encode_detached=$(PKG_BUILD_DIR)/vmlinux-btf \
		$(PKG_BUILD_DIR)/shadow-kernel/vmlinux
endef

define Build/Clean
	rm -rf $(PKG_BUILD_DIR)
endef

define Package/vmlinux-btf/install
	$(INSTALL_DIR) $(1)/usr/lib/debug/boot
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/vmlinux-btf $(1)/usr/lib/debug/boot/vmlinux
	$(LN) vmlinux $(1)/usr/lib/debug/boot/vmlinux-$(LINUX_VERSION)
endef

$(eval $(call BuildPackage,vmlinux-btf))
