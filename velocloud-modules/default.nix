{ lib, stdenv, fetchurl, kernel ? null }:
stdenv.mkDerivation rec {
  inherit (kernel) version src nativeBuildInputs prePatch postPatch;

  name = "velocloud-modules";
  patches = [
    ./patches/0001-hwmon-emc2103-add-support-for-emc2104.patch
    ./patches/0002-gpio-ich-add-workaround-for-bad-velocloud-use_sel.patch
    ./patches/0003-platform-x86-velocloud-edge-5x0-Add-VeloCloud-5X0-pl.patch
    ./patches/0004-igb-handle-velocloud-PHY-on-BB-MDIO.patch
  ];

  makeFlags = [
    "-C" "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "CONFIG_VELOCLOUD_EDGE_5X0=m"
    "CONFIG_SENSORS_EMC2103=m"
    "CONFIG_GPIO_ICH=m"
    "CONFIG_IGB=m"
  ];

  installFlags = [
    "INSTALL_PATH=$(out)"
    "INSTALL_MOD_PATH=$(out)"
  ];

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
    make $makeFlags $installFlags M=$(pwd)/drivers/hwmon modules_install
    make $makeFlags $installFlags M=$(pwd)/drivers/gpio modules_install
    make $makeFlags $installFlags M=$(pwd)/drivers/platform/x86 modules_install
    make $makeFlags $installFlags M=$(pwd)/drivers/net/ethernet/intel/igb modules_install

    mkdir -p $out/etc/depmod.d
    cp ${./depmod-config.conf} $out/etc/depmod.d/velocloud-modules.conf
  '';
}
