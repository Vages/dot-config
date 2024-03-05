{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = with pkgs; [ vim neovim ];

        # formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # allow uninstalling unfree packages
        nixpkgs.config.allowUnfree = true;
        nixpkgs.config.allowUnsupportedSystem = true;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes repl-flake";
        nix.settings.bash-prompt-prefix = "(nix:$name)\\040";
        nix.settings.extra-nix-path = "nixpkgs=flake:nixpkgs";
        nix.extraOptions = ''
          extra-platforms = x86_64-darwin aarch64-darwin
        '';
        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        # This is my try at getting the backspace to work
        system.keyboard.enableKeyMapping = true;
        # system.keyboard.remapCapsLockToControl = true;
        system.keyboard.userKeyMapping = [
          # Caps lock to backspace; keys taken from https://github.com/rossmacarthur/kb-remap/blob/8ad996a86f419a474d7d17e5bc56e55c207bf9dd/README.md#filtering-keyboards
          {
            HIDKeyboardModifierMappingSrc = 30064771129;
            HIDKeyboardModifierMappingDst = 30064771114;
          }
          # Backspace to caps lock
          {
            HIDKeyboardModifierMappingSrc = 30064771114;
            HIDKeyboardModifierMappingDst = 30064771129;
          }
        ];

        # Enable Homebrew (requires you to install homebrew, too)
        homebrew = {
          enable = true;
          casks = [
            "sublime-text"
            "rectangle"
            "flux"
            "mullvad-browser"
            "protonvpn"
            "1password"
            "omnifocus"
            "slack"
            "protonmail-bridge"
            "signal"
            "1password-cli" # Using pkgs._1password did not work
          ];
          onActivation.cleanup = "uninstall";
        };
        system.defaults = {
          dock.autohide = true;
          dock.mru-spaces = false;
          finder.AppleShowAllExtensions = true;
          finder.FXPreferredViewStyle = "clmv";
          screencapture.location = "~/screenshots";
          screensaver.askForPasswordDelay = 10;
          NSGlobalDomain.AppleShowAllFiles = true;
          NSGlobalDomain."com.apple.keyboard.fnState" = true;
          NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = true;
        };
        security.pam.enableSudoTouchIdAuth = true;

        # Declare the user that will be running `nix-darwin`.
        users.users.eirikvageskar = {
          name = "eirikvageskar";
          home = "/Users/eirikvageskar";
        };
      };
      homeconfig = { pkgs, ... }: {
        # this is internal compatibility configuration 
        # for home-manager, don't change this!
        home.stateVersion = "23.05";
        # Let home-manager install and manage itself.
        programs.home-manager.enable = true;

        home.packages = with pkgs; [ nixpkgs-fmt ];

        home.sessionVariables = {
          EDITOR = "subl -w";
        };

        programs.zsh = {
          enable = true;
          shellAliases = {
            switch = "darwin-rebuild switch --flake ~/.config/nix-darwin";
          };
          oh-my-zsh = {
            enable = true;
            plugins = [ "git" ];
            theme = "robbyrussell";
          };
        };

        programs.git = {
          enable = true;
          userName = "Eirik Vågeskar";
          userEmail = "eirik.vaageskar@aboveit.no";
          ignores = [ ".DS_Store" ];
          extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
          };
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."Eirik-sin-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.eirikvageskar = homeconfig;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Eirik-sin-MacBook-Pro".pkgs;
    };
}
