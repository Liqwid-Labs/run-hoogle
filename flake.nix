{
  description = "Run hoogle instances for Haskell projects with Arion.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  # We use this to get the source code of hoogle's HTML parts.
  # This is useful if we want to overwrite certain HTML elements.
  inputs.hoogle.url = "github:ndmitchell/hoogle";
  inputs.hoogle.flake = false;

  outputs = inputs@{ self, nixpkgs, ... }:
    rec {
      supportedSystems = nixpkgs.lib.systems.flakeExposed;
      perSystem = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
      hoogleFor =
        config@{ port ? 8081, local ? true, hoogle-dir ? ./hoogle, ... }: { pkgs, system, project, ... }:
        let
          port' = builtins.toString port;
          opts =
            builtins.concatStringsSep " " [
              (if builtins.isString config.home then "--home " + config.home else "")
              (if builtins.isString config.host then "--host " + config.host else "")
              ("--port " + port')
              (if local then "--local" else "")
            ];
          run-hoogle =
            pkgs.writeShellApplication
              {
                name = "run-hoogle";
                runtimeInputs = project.devShell.${system}.nativeBuildInputs;
                text = ''
                  export LC_CTYPE=C.UTF-8
                  export LC_ALL=C.UTF-8
                  export LANG=C.UTF-8
                  hoogle generate --local --database=local.hoo
                  ${pkgs.coreutils}/bin/coreutils --coreutils-prog=mkdir hoogle
                  ${pkgs.coreutils}/bin/coreutils --coreutils-prog=cp -r ${inputs.hoogle}/* ./hoogle
                  # Overwrites from hoogle directory. This is not really required, but in the future,
                  # we may want to have custom html.
                  ${pkgs.coreutils}/bin/coreutils --coreutils-prog=cp -r ${hoogle-dir}/* ./hoogle
                  hoogle server ${opts} --datadir hoogle --database local.hoo
                '';
              }
          ;
        in
        {
          config.services = {
            webserver = {
              service.useHostStore = true;
              service.command = [
                "${pkgs.bash}/bin/bash"
                "-c"
                ''
                  ${run-hoogle}/bin/run-hoogle
                ''
              ];
              service.ports = [
                "${port'}:${port'}" # host:container
              ];
            };
          };
        };
      launchHoogle = config: project: system: pkgs:
        let
          binPath = "ctl-runtime";
          prebuilt = (pkgs.arion.build {
            inherit pkgs;
            modules = [ (hoogleFor config { inherit pkgs system project; }) ];
          }).outPath;
          script = pkgs.writeShellApplication {
            name = binPath;
            runtimeInputs = [ pkgs.arion pkgs.docker ];
            text =
              ''
                ${pkgs.arion}/bin/arion --prebuilt-file ${prebuilt} up
              '';
          };
        in
        {
          type = "app";
          program = "${script}/bin/${binPath}";
        };
    };
}
