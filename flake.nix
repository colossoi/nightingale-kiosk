{
  description = "Nightingale Karaoke Kiosk";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      nightingale = pkgs.stdenv.mkDerivation {
        pname = "nightingale";
        version = "upstream";

        src = ./nightingale/Nightingale_0.4.0_x86_64.tar.xz;

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.makeWrapper
        ];

        buildInputs = with pkgs; [
          alsa-lib
          at-spi2-atk
          atk
          cairo
          cups
          dbus
          expat
          fontconfig
          freetype
          gdk-pixbuf
          glib
          gtk3
          libdrm
          libgbm
          libGL
          libpulseaudio
          libxkbcommon
          mesa
          nspr
          nss
          pango
          pipewire
          stdenv.cc.cc.lib
          wayland
          xorg.libX11
          xorg.libXcomposite
          xorg.libXcursor
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXi
          xorg.libXrandr
          xorg.libXrender
          xorg.libXScrnSaver
          xorg.libXtst
        ];

        unpackPhase = ''
          mkdir source
          tar -xJf "$src" -C source
        '';

        installPhase = ''
          mkdir -p $out/opt/nightingale
          cp -R source/* $out/opt/nightingale/
          chmod +x $out/opt/nightingale/bin/Nightingale

          mkdir -p $out/bin
          makeWrapper $out/opt/nightingale/bin/Nightingale $out/bin/nightingale
        '';
      };

      commonModules = [
        ./configuration.nix

        ({ pkgs, ... }: {
          environment.systemPackages = [ nightingale ];

          services.cage.program = "${pkgs.writeShellScript "start-nightingale" ''
            export HOME=/home/kiosk
            export XDG_DATA_HOME=/var/lib/nightingale/data
            export XDG_CACHE_HOME=/var/lib/nightingale/cache
            export XDG_CONFIG_HOME=/var/lib/nightingale/config
            exec ${nightingale}/bin/nightingale
          ''}";
        })
      ];

    in
    {
      nixosConfigurations.karaoke = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules;
      };

      packages.${system}.vm = (nixpkgs.lib.nixosSystem {
        inherit system;

        modules = commonModules ++ [
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
          ({ lib, ... }: {
            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

            virtualisation = {
              memorySize = 4096;
              cores = 2;
              diskSize = 8192;
              graphics = true;
              qemu.options = [
                "-device virtio-gpu-pci"
                "-display gtk,gl=on"
                "-device intel-hda"
                "-device hda-duplex"
              ];
            };
          })
        ];
      }).config.system.build.vm;

      packages.${system}.iso = (nixpkgs.lib.nixosSystem {
        inherit system;

        modules = commonModules ++ [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ lib, ... }: {
            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
          })
        ];
      }).config.system.build.isoImage;
    };
}
