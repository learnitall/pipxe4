# piPXE4 - iPXE for the Raspberry Pi 4

[![Build](https://img.shields.io/github/workflow/status/learnitall/pipxe4/Build)](https://github.com/ipxe/pipxe/actions?query=workflow%3ABuild+branch%3Amaster)
[![Release](https://img.shields.io/github/v/release/learnitall/pipxe4)](https://github.com/learnitall/pipxe4/releases/latest)

piPXE4 is a fork of [piPXE] for the [Raspberry Pi 4 Model B].

> [piPXE] is a build of the [iPXE] network boot firmware for the
> [Raspberry Pi].

Please read [TianoCore EKD2's Notes] on the state of their Raspberry
Pi 4's boot firmware for limitations and further usage instructions.

## Usage

There a couple of different ways that piPXE4 can be used:

### PXE Chainloading

1. Using [Raspbian Lite] (or your favorite equivalent that can also
adjust the EEPROM), boot up your Raspberry Pi and adjust the
`BOOT_ORDER` configuration [in the bootloader] to include PXE booting
from the network.
1. Shut down your Raspberry Pi.
1. Download [pipxe4.zip] and copy the contents into your tftp server.
1. Setup your dhcp server to let the Raspberry Pi perform its standard
network boot with the aforementioned tftp server. The Pi will identify
itself with the following vendor class: `PXEClient:Arch:00000:UNDI:002001`
1. Setup your dhcp server to handle when the Raspberry Pi performs a
PXE boot using the UEFI firmware it just pulled from your tftp server.
You need to set the boot file to the built iPXE efi firmware.
This by default is located at `efi/boot/bootaa64.efi` within `pipxe4.zip`.
In this stage, the Pi will identify itself with the following vendor
class: `PXEClient:Arch:00011:UNDI:003000`
1. Setup your dhcp server to handle when the Raspberry Pi loads the
iPXE firmware from your tftp server and begins booting using iPXE.
1. Power on your Raspberry Pi.

### USB Drive

1. Using [Raspbian Lite] (or your favorite equivalent that can also
adjust the EEPROM), boot up your Raspberry Pi and adjust the
`BOOT_ORDER` configuration [in the bootloader] to include booting
from a USB drive.
1. Shut down your Raspberry Pi.
2. Download [pipxe4.img] and write it onto a blank USB drive.
3. Insert the USB drive into your Raspberry Pi.
4. Power on your Raspberry Pi.

### SD Card

1. Download [pipxe4.img] and write it onto any blank micro SD card.
2. Insert the micro SD card into your Raspberry Pi.
3. Power on your Raspberry Pi.

Within a few seconds you should see iPXE appear and begin booting from
the network. When adjusting you Pi's bootloader configuration, feel free
to adjust any other variables you might need for your setup, such as such
as `TFTP_PREFIX`.

## Building from source

To build from source, clone this repository and run `make`.  This will
build all of the required components and eventually generate the firmware
image [pipxe4.img] and zip [pipxe4.zip].

You will need various build tools installed, including a
cross-compiling version of `gcc` for building AArch64 binaries.

> (learnitall) Note: Most documentation for EDK2 mentions
> building on Ubuntu 16.04 using gcc5, however I am unable to get
> a successful compile. I've had more luck using Ubuntu 20.04 and
> gcc9, which I found referenced in [build.yml], even though
> the configured toolchain remains set to `GCC5`.

Fedora build tools:

    sudo dnf install -y binutils gcc gcc-aarch64-linux-gnu \
                        git-core iasl libuuid-devel make \
                        mtools perl python subversion xz-devel

Ubuntu build tools:

    sudo apt install -y build-essential gcc-aarch64-linux-gnu \
                        git iasl lzma-dev mtools perl python \
                        subversion uuid-dev

For convenience, a Containerfile has been provided to setup a
build environment. Use the repo's root as the build context.

Building the firmware from scratch manually:

    make submodules
    podman build . -t pipxe4
    podman run --name pipxe4 pipxe4
    podman cp pipxe4:/opt/pipxe4.img pipxe4.img
    podman cp pipxe4:/opt/pipxe4.zip pipxe4.zip

Building using make:

    make image
    make image_build

Cleanup:

    podman rmi pipxe4
    podman rm pipxe4


## 3 GB Ram Limit

By default, the edk2 UEFI firmware limits the amount of ram to 3GB.
A version of the firmware with this setting disabled by default instead can be built
as follows:

    make image
    podman run --name pipxe4 -it pipxe4 /bin/bash
    # Within the container:
    make -C /opt disable-ram-limit
    make -C /opt
    exit
    # Copy results
    make image_copy

For more information on this, check out:

* [TianoCore EKD2's Notes]
* [Notice in pftf/RPi4 Readme]

## GZIP Image Support

By default, iPXE does not come built with GZIP image support. To enable this,
run the same steps as above, but rather than `make -C /opt disable-ram-limit`,
use: `make -C /opt enable-gzip`

For more information on this, check out:

* [ipxe/ipxe#d7bc9e9]
* [imgextract]

## iPXE by Default

The edk2 firmware will always attempt to boot from detected disks before
attempting to boot with iPXE. This makes provision management services,
such as [The Foreman] or [foremanlite], unable to properly manage the device's
lifecycle and perform tasks such as re-provisioning. To get around this, a
patch for the edk2 firmware is provided, which modified the boot order to always
attempt an iPXE boot from the first detected network device.

To enable this, use the same steps as with other included patches in this
repository, except use the target `default-pxe-boot`

## How it works

The [Raspberry Pi Boot] process essentially does the following:

1. Using the [First Stage Bootloader], load the [Second Stage Bootloader] from
2. the [EEPROM].
3. Using the [Second Stage Bootloader], read the [EEPROM] configuration file to
determine the boot type.
1. Using the configured boot type (i.e. USB, SDCard, Network), load firmware,
kernels, extra configuration, etc as needed to boot the OS.

This repository contains:

* [TianoCore EDK2] UEFI firmware built for the [RPi4] platform: `RPI_EFI.fd`
* [iPXE] built for the `arm64-efi` platform: `/efi/boot/bootaa64.efi`

The [TianoCore EDK2] UEFI firmware is compatible with iPXE, therefore we use the
Raspberry Pi 4's boot process to load the UEFI firmware, which is then used
to load iPXE.

## License

Every component is under an open source license.  See the individual
subproject licensing terms for more details:

* <https://github.com/raspberrypi/firmware/blob/master/boot/LICENCE.broadcom>
* <https://github.com/tianocore/edk2/blob/master/Readme.md>
* <https://ipxe.org/licensing>

[iPXE]: https://ipxe.org
[piPXE]: https://github.com/ipxe/pipxe
[Raspberry Pi]: https://www.raspberrypi.org
[Raspberry Pi 4 Model B]: https://www.raspberrypi.com/products/raspberry-pi-4-model-b/
[pipxe4.img]: https://github.com/learnitall/pipxe4/releases/latest/download/pipxe4.img
[pipxe4.zip]: https://github.com/learnitall/pipxe4/releases/latest/download/pipxe4.zip
[TianoCore EDK2]: https://github.com/tianocore/edk2
[Using EDK II with Native GCC]: https://github.com/tianocore/tianocore.github.io/wiki/Using-EDK-II-with-Native-GCC
[RPi4]: https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/RPi4
[build.yml]: https://github.com/ipxe/pipxe/tree/master/.github/workflows
[Raspberry Pi Boot]: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#first-stage-bootloader
[in the bootloader]: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-4-bootloader-configuration
[Raspbian Lite]: https://www.raspberrypi.org/downloads/raspbian/
[EEPROM]: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-4-boot-eeprom
[Second Stage Bootloader]: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#second-stage-bootloader
[First Stage Bootloader]: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#first-stage-bootloader
[TianoCore EKD2's Notes]: https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/RPi4#notes
[Notice in pftf/RPi4 Readme]: https://github.com/pftf/RPi4/blob/master/Readme.md#initial-notice
[imgextract]: https://ipxe.org/cmd/imgextract
[ipxe/ipxe#d7bc9e9]: https://github.com/ipxe/ipxe/commit/d7bc9e9d67c2e7a4d2006d2c48485b3265aea038
[The Foreman]: https://theforeman.org
[foremanlite]: https://github.com/learnitall/foremanlite