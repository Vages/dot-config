{
  description = "Eirik Vaageskar’s Nix configuration";

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

  outputs = { self, nix-darwin, nixpkgs, home-manager }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = with pkgs; [
          devenv
          direnv
          docker
          neovim
          tree
          vim
        ];

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;

        nix = {
          package = pkgs.nix;
          settings = {
            # Necessary for using flakes on this system.
            experimental-features = "nix-command flakes repl-flake";
            bash-prompt-prefix = "(nix:$name)\\040";
            extra-nix-path = "nixpkgs=flake:nixpkgs";
          };
          extraOptions = ''
            extra-platforms = x86_64-darwin aarch64-darwin
          '';
        };

        nixpkgs = {
          config = {
            # allow uninstalling unfree packages
            allowUnfree = true;
            allowUnsupportedSystem = true;
          };

          # The platform the configuration will be used on.
          hostPlatform = "aarch64-darwin";

        };

        # zsh must be enabled here as well as in the home manager
        programs.zsh.enable = true;

        system = {
          # Set Git commit hash for darwin-version.
          configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          stateVersion = 4;

          keyboard = {
            enableKeyMapping = true;
            userKeyMapping =
              let
                # Keyboard key "base", 0x700000000, in decimal: 
                # https://developer.apple.com/library/archive/technotes/tn2450/_index.html#//apple_ref/doc/uid/DTS40017618-CH1-TNTAG8
                # Nix does not yet have hexadecimal number support,
                # see https://github.com/NixOS/nix/issues/7578)
                base = 30064771072;
                # Keys are calculated as the base + the key value from this table:
                # https://developer.apple.com/library/archive/technotes/tn2450/_index.html#//apple_ref/doc/uid/DTS40017618-CH1-KEY_TABLE_USAGES
                caps_lock_key = base + 3 * 16 + 9;
                backspace_key = base + 2 * 16 + 10;
                application_key = base + 6 * 16 + 5; # The key between Alt Gr and Ctrl on my Microsoft Ergonomic Keyboard.
                right_alt_key = base + 14 * 16 + 6;
              in
              [
                {
                  HIDKeyboardModifierMappingSrc = caps_lock_key;
                  HIDKeyboardModifierMappingDst = backspace_key;
                }
                {
                  HIDKeyboardModifierMappingSrc = backspace_key;
                  HIDKeyboardModifierMappingDst = caps_lock_key;
                }
                {
                  HIDKeyboardModifierMappingSrc = application_key;
                  HIDKeyboardModifierMappingDst = right_alt_key;
                }
              ];
          };

          defaults = {
            dock = {
              appswitcher-all-displays = true;
              autohide = true;
              mru-spaces = false;
            };
            finder = {
              AppleShowAllExtensions = true;
              FXPreferredViewStyle = "clmv";
            };
            menuExtraClock.IsAnalog = true;
            screencapture.location = "~/screenshots"; # Create directory to have an effect
            screensaver.askForPasswordDelay = 10;
            NSGlobalDomain = {
              "com.apple.keyboard.fnState" = true;
              AppleInterfaceStyleSwitchesAutomatically = true;
              AppleShowAllFiles = true;
              AppleShowScrollBars = "Always";
              NSAutomaticPeriodSubstitutionEnabled = false;
            };
          };
        };


        # Enable Homebrew (requires you to install homebrew, too)
        homebrew = {
          enable = true;
          brews = [
            "cocoapods"
          ];
          casks = [
            "1password"
            "1password-cli" # Using pkgs._1password did not work
            "alfred"
            "caffeine"
            "docker"
            "dropbox"
            "firefox"
            "flux"
            "goland"
            "intellij-idea"
            "megasync"
            "microsoft-teams"
            "mullvad-browser"
            "obsidian"
            "omnifocus"
            "postman"
            "protonmail-bridge"
            "protonvpn"
            "rectangle"
            "rocket"
            "signal"
            "slack"
            "spotify"
            "sublime-text"
            "visual-studio-code"
            "vivaldi"
            "vlc"
            "webstorm"
            # Flutter development/begin
            "android-studio"
            "flutter"
            "google-chrome"
            # Flutter development/end
          ];
          masApps = {
            "1Password for Safari" = 1569813296;
            "TextSniper" = 1528890965;
            "Tripsy" = 1429967544;
            "WireGuard" = 1451685025;
            "Xcode" = 497799835;
          };
          onActivation.cleanup = "uninstall";
        };
        security.pam.enableSudoTouchIdAuth = true;

        # Declare the user that will be running `nix-darwin`.
        users.users.eirikvageskar = {
          name = "eirikvageskar";
          home = "/Users/eirikvageskar";
        };
      };
      homeconfig = { pkgs, ... }: {
        home = {
          # this is internal compatibility configuration 
          # for home-manager, don't change this!
          stateVersion = "23.05";

          packages = with pkgs; [
            bat # cat/less, with syntax highligting
            bat-extras.batman # man, with syntax highligthing
            curlie
            delta
            difftastic
            fd
            git-filter-repo
            go-jira
            httpie
            jq
            lynx
            nixpkgs-fmt
            nodePackages.prettier
            nodejs_22
            scc
            shellcheck
            shfmt
            silver-searcher
          ];
          sessionVariables = {
            EDITOR = "subl -w";
          };

        };

        programs = {
          # Let home-manager install and manage itself.
          home-manager.enable = true;

          zsh = {
            enable = true;
            syntaxHighlighting.enable = true;
            shellAliases = {
              switch = "darwin-rebuild switch --flake ~/.config/nix-darwin";
              dk = "docker";
              dkc = "docker compose";
              dkcp = "docker compose pull";
              dkcd = "docker compose down";
              dkcu = "docker compose up";
            };
            initExtra = ''
              eval "$(jira --completion-script-zsh)" # go-jira tab completion script: https://github.com/go-jira/jira?tab=readme-ov-file#setting-up-tab-completion
            '';
            oh-my-zsh = {
              enable = true;
              plugins = [
                "direnv"
                "git"
                "ssh-agent"
                "vscode"
              ];
              theme = "robbyrussell";
            };
          };

          git = {
            enable = true;
            userName = "Eirik Vågeskar";
            userEmail = "eirik.vaageskar@aboveit.no";
            ignores = [ ".DS_Store" ];
            extraConfig = {
              init.defaultBranch = "main";
              push.autoSetupRemote = true;
              pull.rebase = true;
              rebase.autoSquash = true;

              # Delta, source: https://github.com/dandavison/delta?tab=readme-ov-file#get-started
              core.pager = "delta --tabs 2";
              interactive.diffFilter = "delta --color-only";
              delta = {
                navigate = true; # use n and N to move between diff sections
                light = true; # set to true if you're in a terminal w/ a light background color (e.g. the default macOS terminal)
              };
              merge.conflictstyle = "diff3";
              diff.colorMoved = "default";

              # Difftastic, source: https://difftastic.wilfred.me.uk/git.html#regular-usage
              diff.tool = "difftastic"; # this is from diffTastic
              difftool = {
                prompt = false;
                difftastic.cmd = "difft \"$LOCAL\" \"$REMOTE\"";
              };
              pager.difftool = true;

              alias.dshow = "-c diff.external=difft show -p --ext-diff";

              # Necessary to fetch private go modules for tidir projects
              url."ssh://git@bitbucket.org/".insteadOf = "https://bitbucket.org/";
            };
            includes = [{
              condition = "gitdir:~/zaveit/";
              path = "~/zaveit/.gitconfig";
            }
              {
                condition = "gitdir:~/private-git/";
                path = "~/private-git/.gitconfig";
              }];
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
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              verbose = true;
              users.eirikvageskar = homeconfig;
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Eirik-sin-MacBook-Pro".pkgs;
    };
}
