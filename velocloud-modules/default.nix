{ lib, stdenv, fetchurl, kernel ? null }:
stdenv.mkDerivation rec {
  inherit (kernel) version src nativeBuildInputs postPatch modDirVersion;

  name = "velocloud-modules";
  patches = [
    ./patches/0001-hwmon-emc2103-add-support-for-emc2104.patch
    ./patches/0002-gpio-ich-add-workaround-for-bad-velocloud-use_sel.patch
    ./patches/0003-platform-x86-velocloud-edge-5x0-Add-VeloCloud-5X0-pl.patch
    ./patches/0004-igb-handle-velocloud-PHY-on-BB-MDIO.patch
  ];

  extraMakeFlags = [
    "CONFIG_VELOCLOUD_EDGE_5X0=m"
    "CONFIG_SENSORS_EMC2103=m"
    "CONFIG_GPIO_ICH=m"
    "CONFIG_IGB=m"
  ];

  makeFlags = [
    "-C" "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ] ++ extraMakeFlags;

  buildPhase = ''
    make $makeFlags M=$(pwd)/drivers/hwmon emc2103.o
    make $makeFlags M=$(pwd)/drivers/hwmon emc2103.ko

    make $makeFlags M=$(pwd)/drivers/gpio gpio-ich.o
    make $makeFlags M=$(pwd)/drivers/gpio gpio-ich.ko

    make $makeFlags M=$(pwd)/drivers/platform/x86 velocloud-edge-5x0.o
    make $makeFlags M=$(pwd)/drivers/platform/x86 velocloud-edge-5x0.ko

    make $makeFlags M=$(pwd)/drivers/net/ethernet/intel/igb modules
  '';

  installPhase = ''
    mkdir -p $out/lib/modules/${modDirVersion}/extra/

    xz --check=crc32 --lzma2=dict=1MiB $(pwd)/drivers/hwmon/emc2103.ko
    cp $(pwd)/drivers/hwmon/emc2103.ko.xz $out/lib/modules/${modDirVersion}/extra/

    xz --check=crc32 --lzma2=dict=1MiB $(pwd)/drivers/gpio/gpio-ich.ko
    cp $(pwd)/drivers/gpio/gpio-ich.ko.xz $out/lib/modules/${modDirVersion}/extra/

    xz --check=crc32 --lzma2=dict=1MiB $(pwd)/drivers/platform/x86/velocloud-edge-5x0.ko
    cp $(pwd)/drivers/platform/x86/velocloud-edge-5x0.ko.xz $out/lib/modules/${modDirVersion}/extra/

    xz --check=crc32 --lzma2=dict=1MiB $(pwd)/drivers/net/ethernet/intel/igb/igb.ko
    cp $(pwd)/drivers/net/ethernet/intel/igb/igb.ko.xz $out/lib/modules/${modDirVersion}/extra/

    mkdir -p $out/etc/depmod.d
    cp ${./depmod-config.conf} $out/etc/depmod.d/velocloud-modules.conf
  '';
}
