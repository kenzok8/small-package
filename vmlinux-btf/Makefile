# SPDX-License-Identifier: GPL-3.0-only
#
# Detached kernel BTF for CO-RE eBPF (dae/daed) on firmware whose kernel was
# built without CONFIG_DEBUG_INFO_BTF. Builds a shadow kernel from the same
# OpenWrt source + .config with BTF enabled, then pahole-encodes a detached
# vmlinux.btf. cilium/ebpf finds it at /usr/lib/debug/boot/vmlinux-<release>.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=vmlinux-btf
# SDK 内核常落后于目标固件，允许单独指定影子内核版本
BTF_KERNEL_VERSION?=$(LINUX_VERSION)
PKG_VERSION:=$(BTF_KERNEL_VERSION)
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
KERNEL_MAJOR:=$(firstword $(subst ., ,$(BTF_KERNEL_VERSION)))
BTF_LINUX_SOURCE:=linux-$(BTF_KERNEL_VERSION)$(if $(findstring -rc,$(BTF_KERNEL_VERSION)),.tar.gz,.tar.xz)
LINUX_TARBALL_URL:=https://cdn.kernel.org/pub/linux/kernel/v$(KERNEL_MAJOR).x/$(BTF_LINUX_SOURCE)
# KERNEL_MAKE_FLAGS 里的 KERNELRELEASE 来自 SDK 内核，覆盖时一并改
BTF_KERNEL_MAKE_FLAGS =$(filter-out KERNELRELEASE=%,$(KERNEL_MAKE_FLAGS)) KERNELRELEASE=$(BTF_KERNEL_VERSION)

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR) $(DL_DIR)
	[ -f "$(DL_DIR)/$(BTF_LINUX_SOURCE)" ] || \
		wget -nv -O "$(DL_DIR)/$(BTF_LINUX_SOURCE)" "$(LINUX_TARBALL_URL)"
	$(TAR) -C $(PKG_BUILD_DIR) -xf $(DL_DIR)/$(BTF_LINUX_SOURCE)
	mv $(PKG_BUILD_DIR)/linux-$(BTF_KERNEL_VERSION) $(PKG_BUILD_DIR)/shadow-kernel
	cp $(LINUX_DIR)/.config $(PKG_BUILD_DIR)/shadow-kernel/.config
endef

define Build/Compile
	# 影子内核开 DEBUG_INFO_BTF，链接 vmlinux 与后续 pahole 编码都需要 pahole。
	# 部分 SDK 镜像里没有 pahole（armv7 imx 等目标默认不开 BTF），这里直接从
	# dwarves 源码现编一个装到 staging host 目录；版本与哈希同上游 tools/dwarves
	# 保持一致，已装好就跳过。注意：SDK 的 tools/dwarves 编译目标在实测里不可用，
	# 不要改回那条路。另外这段 recipe 会被 make 展开两次，shell 变量写了也活不下来，
	# 所以只用 make 变量写死路径与并行数，不要用双美元转义。
	if [ -x "$(STAGING_DIR_HOST)/bin/pahole" ]; then \
		echo "pahole already present, skipping dwarves build"; \
	else \
		[ -f "$(DL_DIR)/dwarves-1.28.tar.bz2" ] || \
			wget -nv -O "$(DL_DIR)/dwarves-1.28.tar.bz2" \
				"https://fedorapeople.org/~acme/dwarves/dwarves-1.28.tar.bz2"; \
		echo "826efc0fc9237d3c1e9c01553ea387a8cb46e8dc119ff863889043f4ed54b2ae  $(DL_DIR)/dwarves-1.28.tar.bz2" | sha256sum -c -; \
		rm -rf $(PKG_BUILD_DIR)/dwarves-build; \
		mkdir -p $(PKG_BUILD_DIR)/dwarves-build; \
		tar -xjf "$(DL_DIR)/dwarves-1.28.tar.bz2" -C $(PKG_BUILD_DIR)/dwarves-build --strip-components=1; \
		cd $(PKG_BUILD_DIR)/dwarves-build && \
			PATH="$(STAGING_DIR_HOST)/bin:$(PATH)" \
			PKG_CONFIG_PATH="$(STAGING_DIR_HOST)/lib/pkgconfig" \
			$(if $(wildcard $(STAGING_DIR_HOST)/bin/cmake),$(STAGING_DIR_HOST)/bin/cmake,cmake) \
				-DCMAKE_INSTALL_PREFIX="$(STAGING_DIR_HOST)" \
				-DCMAKE_BUILD_TYPE=Release \
				-DCMAKE_FIND_ROOT_PATH="$(STAGING_DIR_HOST)" \
				-DCMAKE_PREFIX_PATH="$(STAGING_DIR_HOST)" \
				-D__LIB=lib \
				-DCMAKE_INSTALL_RPATH="$(STAGING_DIR_HOST)/lib" \
				-DCMAKE_SKIP_RPATH=FALSE . && \
			$(MAKE) -j$(shell nproc) && \
			$(MAKE) install; \
	fi

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
		$(BTF_KERNEL_MAKE_FLAGS) \
		KBUILD_HOSTLDFLAGS="$(KBUILD_HOSTLDFLAGS) -lz" \
		olddefconfig

	$(MAKE) -C $(PKG_BUILD_DIR)/shadow-kernel \
		$(BTF_KERNEL_MAKE_FLAGS) \
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
	$(LN) vmlinux $(1)/usr/lib/debug/boot/vmlinux-$(BTF_KERNEL_VERSION)
endef

$(eval $(call BuildPackage,vmlinux-btf))
