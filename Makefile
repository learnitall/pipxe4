FW_BASE_URL		:= https://github.com/raspberrypi/firmware/branches/stable/boot

EFI_BUILD	:= RELEASE
EFI_ARCH	:= AARCH64
EFI_TOOLCHAIN	:= GCC5
EFI_TIMEOUT	:= 3
EFI_FLAGS	:= --pcd=PcdPlatformBootTimeOut=$(EFI_TIMEOUT)
EFI_DSC		:= edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc
EFI_FD		:= Build/RPi4/$(EFI_BUILD)_$(EFI_TOOLCHAIN)/FV/RPI_EFI.fd

IPXE_CROSS	:= aarch64-linux-gnu-
IPXE_SRC	:= ipxe/src
IPXE_TGT	:= bin-arm64-efi/rpi.efi
IPXE_EFI	:= $(IPXE_SRC)/$(IPXE_TGT)

BASETOOLS_SRC   := edk2/BaseTools

IMG_MB			:= 32
export MTOOLSRC	:= mtoolsrc

SHELL		:= /bin/bash

all : pipxe4 pipxe4.img pipxe4.zip

submodules :
	git submodule update --init --recursive

firmware :
	if [ ! -e firmware ] ; then \
		$(RM) -rf firmware_tmp ; \
		mkdir firmware_tmp ; \
		while read FILE; do \
			curl --output firmware_tmp/$$FILE -L "$(FW_BASE_URL)/$$FILE" ; \
		done < firmware.txt ; \
		mv firmware_tmp firmware ; \
	fi

efi : $(EFI_FD)

efi-basetools : submodules
	$(MAKE) -C edk2/BaseTools

$(EFI_FD) : submodules efi-basetools
	. ./edksetup.sh && \
	build -b $(EFI_BUILD) -a $(EFI_ARCH) -t $(EFI_TOOLCHAIN) \
		-p $(EFI_DSC) $(EFI_FLAGS)

ipxe : $(IPXE_EFI)

$(IPXE_EFI) : submodules
	$(MAKE) -C $(IPXE_SRC) CROSS=$(IPXE_CROSS) CONFIG=rpi $(IPXE_TGT)

pipxe4 : firmware efi ipxe
	$(RM) -rf pipxe4
	mkdir -p pipxe4
	cp -r $(sort $(filter-out firmware/kernel%,$(wildcard firmware/*))) \
		pipxe4/
	cp config.txt $(EFI_FD) edk2/License.txt pipxe4/
	mkdir -p pipxe4/efi/boot
	cp $(IPXE_EFI) pipxe4/efi/boot/bootaa64.efi
	cp ipxe/COPYING* pipxe4/

pipxe4.img : pipxe4
	truncate -s $(IMG_MB)M $@
	mpartition -I -c -b 32 -s 32 -h 64 -t $(IMG_MB) -a "z:"
	mformat -v "piPXE4" "z:"
	mcopy -s pipxe4/* "z:"

pipxe4.zip : pipxe4
	$(RM) -f $@
	( pushd $< ; zip -q -r ../$@ * ; popd )

tag :
	git tag v`git show -s --format='%ad' --date=short | tr -d -`

.PHONY : submodules firmware efi efi-basetools $(EFI_FD) ipxe $(IPXE_EFI) \
	pipxe4 pipxe4.img

image : submodules
	podman build . -t pipxe4

image_build :
	podman run -it --name pipxe4 pipxe4
	podman cp pipxe4:/opt/pipxe4.img pipxe4.img
	podman cp pipxe4:/opt/pipxe4.zip pipxe4.zip

clean :
	$(RM) -rf firmware Build pipxe4 pipxe4 pipxe4
	if [ -d $(IPXE_SRC) ] ; then $(MAKE) -C $(IPXE_SRC) clean ; fi
	if [ -d ${BASETOOLS_SRC} ] ; then $(MAKE) -C $(BASETOOLS_SRC) clean ; fi
