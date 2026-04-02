{ config, pkgs, lib, ... }:

{
  system.stateVersion = "25.05";

  networking.hostName = "karaoke";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Graphics / Wayland
  hardware.graphics.enable = true;
  services.libinput.enable = true;

  # Enable Xwayland support
  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = false;
  services.xserver.desktopManager.xterm.enable = false;

  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = false;
  };

  # Allow running upstream binaries
  programs.nix-ld.enable = true;

  # Kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    description = "Kiosk user";
    extraGroups = [ "audio" "video" "networkmanager" ];
    initialPassword = "kiosk";
  };

  # Nightingale storage on internal disk
  systemd.tmpfiles.rules = [
    "d /var/lib/nightingale 0755 kiosk users - -"
    "d /var/lib/nightingale/data 0755 kiosk users - -"
    "d /var/lib/nightingale/cache 0755 kiosk users - -"
    "d /var/lib/nightingale/config 0755 kiosk users - -"
  ];

  # Mount USB drive labeled MUSIC at /mnt/music
  fileSystems."/mnt/music" = {
    device = "/dev/disk/by-label/MUSIC";
    fsType = "auto";
    options = [ "nofail" "x-systemd.automount" "x-systemd.idle-timeout=5min" "rw" ];
  };

  services.udisks2.enable = true;

  # Cage kiosk compositor
  services.cage = {
    enable = true;
    user = "kiosk";
    extraArguments = [ "-s" "--xwayland" ];
  };

  # Hide cursor
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # SSH for remote maintenance
  services.openssh.enable = true;

  # Basic tools for debugging
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    pciutils
    usbutils
    psmisc
  ];

  networking.firewall.enable = true;
}
