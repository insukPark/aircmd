#
# MT7621 Profiles
#

KERNEL_DTB += -d21
DEVICE_VARS += TPLINK_BOARD_ID TPLINK_HEADER_VERSION TPLINK_HWID TPLINK_HWREV

define Build/elecom-gst-factory
  $(eval product=$(word 1,$(1)))
  $(eval version=$(word 2,$(1)))
  ( $(STAGING_DIR_HOST)/bin/mkhash md5 $@ | tr -d '\n' ) >> $@
  ( \
    echo -n "ELECOM $(product) v$(version)" | \
      dd bs=32 count=1 conv=sync; \
    dd if=$@; \
  ) > $@.new
  mv $@.new $@
  echo -n "MT7621_ELECOM_$(product)" >> $@
endef

define Build/elecom-wrc-factory
  $(eval product=$(word 1,$(1)))
  $(eval version=$(word 2,$(1)))
  $(STAGING_DIR_HOST)/bin/mkhash md5 $@ >> $@
  ( \
    echo -n "ELECOM $(product) v$(version)" | \
      dd bs=32 count=1 conv=sync; \
    dd if=$@; \
  ) > $@.new
  mv $@.new $@
endef

define Build/iodata-factory
  $(eval fw_size=$(word 1,$(1)))
  $(eval fw_type=$(word 2,$(1)))
  $(eval product=$(word 3,$(1)))
  $(eval factory_bin=$(word 4,$(1)))
  if [ -e $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) -a "$$(stat -c%s $@)" -lt "$(fw_size)" ]; then \
    $(CP) $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) $(factory_bin); \
    $(STAGING_DIR_HOST)/bin/mksenaofw \
      -r 0x30a -p $(product) -t $(fw_type) \
      -e $(factory_bin) -o $(factory_bin).new; \
    mv $(factory_bin).new $(factory_bin); \
    $(CP) $(factory_bin) $(BIN_DIR)/; \
	else \
		echo "WARNING: initramfs kernel image too big, cannot generate factory image" >&2; \
	fi
endef

# The OEM webinterface expects an kernel with initramfs which has the uImage
# header field ih_name.
# We don't wan't to set the header name field for the kernel include in the
# sysupgrade image as well, as this image shouldn't be accepted by the OEM
# webinterface. It will soft-brick the board.
define Build/wr1201-factory-header
	mkimage -A $(LINUX_KARCH) \
		-O linux -T kernel \
		-C lzma -a $(KERNEL_LOADADDR) -e $(if $(KERNEL_ENTRY),$(KERNEL_ENTRY),$(KERNEL_LOADADDR)) \
		-n 'WR1201_8_128' -d $@ $@.new
	mv $@.new $@
endef

define Build/netis-tail
	echo -n $(1) >> $@
	echo -n $(UIMAGE_NAME)-yun | $(STAGING_DIR_HOST)/bin/mkhash md5 | \
		sed 's/../\\\\x&/g' | xargs echo -ne >> $@
endef

define Build/ubnt-erx-factory-image
	if [ -e $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) -a "$$(stat -c%s $@)" -lt "$(KERNEL_SIZE)" ]; then \
		echo '21001:6' > $(1).compat; \
		$(TAR) -cf $(1) --transform='s/^.*/compat/' $(1).compat; \
		\
		$(TAR) -rf $(1) --transform='s/^.*/vmlinux.tmp/' $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE); \
		mkhash md5 $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) > $(1).md5; \
		$(TAR) -rf $(1) --transform='s/^.*/vmlinux.tmp.md5/' $(1).md5; \
		\
		echo "dummy" > $(1).rootfs; \
		$(TAR) -rf $(1) --transform='s/^.*/squashfs.tmp/' $(1).rootfs; \
		\
		mkhash md5 $(1).rootfs > $(1).md5; \
		$(TAR) -rf $(1) --transform='s/^.*/squashfs.tmp.md5/' $(1).md5; \
		\
		echo '$(BOARD) $(VERSION_CODE) $(VERSION_NUMBER)' > $(1).version; \
		$(TAR) -rf $(1) --transform='s/^.*/version.tmp/' $(1).version; \
		\
		$(CP) $(1) $(BIN_DIR)/; \
	else \
		echo "WARNING: initramfs kernel image too big, cannot generate factory image" >&2; \
	fi
endef

define Device/zbt-wg3526-16M
#  DTS := ZBT-WG3526-16M
  DTS := VT-VX2000-16M
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  SUPPORTED_DEVICES += zbt-wg3526
  DEVICE_TITLE := VX2000-EVK
#  DEVICE_TITLE := ZBT WG3526 (16MB flash)
  DEVICE_PACKAGES := \
	kmod-ata-core kmod-ata-ahci kmod-sdhci-mt7620 kmod-mt7603 kmod-mt76x2 \
	kmod-usb3 kmod-usb-ledtrig-usbport wpad-basic
endef
TARGET_DEVICES += zbt-wg3526-16M

define Device/vt-vx2000-16M
  DTS := VT-VX2000-16M
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  SUPPORTED_DEVICES += vt-vx2000
  DEVICE_TITLE := VX2000
  DEVICE_PACKAGES := \
	kmod-ata-core kmod-ata-ahci kmod-sdhci-mt7620 kmod-mt7603 kmod-mt76x2 \
	kmod-usb-ledtrig-usbport wpad hostapd-utils
endef
TARGET_DEVICES += vt-vx2000-16M

define Device/zbt-wg3526-32M
  DTS := ZBT-WG3526-32M
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  SUPPORTED_DEVICES += ac1200pro
  DEVICE_TITLE := ZBT WG3526 (32MB flash)
  DEVICE_PACKAGES := \
	kmod-ata-core kmod-ata-ahci kmod-sdhci-mt7620 kmod-mt7603 kmod-mt76x2 \
	kmod-usb3 kmod-usb-ledtrig-usbport wpad-basic
endef
TARGET_DEVICES += zbt-wg3526-32M
