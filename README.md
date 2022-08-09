# Run Hoogle

Run Hoogle instances using Arion.

Example flake:
```nix
{
  description = "Agora hoogle instance";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  inputs.agora.url = "github:Liqwid-Labs/agora";
  inputs.run-hoogle.url = "github:Liqwid-labs/run-hoogle";

  outputs = inputs@{ self, nixpkgs, run-hoogle, ... }:
    {
      apps = run-hoogle.perSystem (system:
        let
          pkgs = run-hoogle.pkgsFor system;
          config = {
            home = "https://hoogle.nix.dance";
            host = "'*'";
            port = 8081;
            local = true;
          };
        in
        { agoraHoogle = run-hoogle.launchHoogle config inputs.agora system pkgs; }
      );
    };
}
```
