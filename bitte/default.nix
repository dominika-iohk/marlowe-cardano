{ marlowe-playground, marlowe-pab, web-ghc, marlowe-dashboard, cardano-node, cardano-wallet, plutus-chain-index, docs, pkgs, sources }:
let
  staticSite = pkgs.callPackage (sources.plutus-apps + "/bitte/static-site.nix") { };
  playgroundStatic = pkgs.callPackage (sources.plutus-apps + "/bitte/playground-static.nix") { inherit staticSite; docs = docs.site; };
in
{
  web-ghc-server-entrypoint = pkgs.callPackage ./web-ghc-server.nix {
    web-ghc-server = web-ghc;
  };

  marlowe-playground-server-entrypoint = pkgs.callPackage (sources.plutus-apps + "/bitte/plutus-playground-server.nix") {
    variant = "marlowe";
    pkg = marlowe-playground.server;
  };
  marlowe-playground-client-entrypoint = playgroundStatic {
    client = marlowe-playground.client;
    variant = "marlowe";
  };

  marlowe-run-entrypoint = pkgs.callPackage ./pab.nix {
    pabExe = "${marlowe-pab}/bin/marlowe-pab";
    staticPkg = marlowe-dashboard.client;
  };

  node = pkgs.callPackage ./node {
    inherit cardano-node;
  };

  wbe = pkgs.callPackage ./wbe.nix { inherit cardano-wallet; };

  chain-index = pkgs.callPackage ./chain-index.nix { inherit plutus-chain-index; };
}
