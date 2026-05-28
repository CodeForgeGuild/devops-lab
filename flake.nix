{
  description = "GitOps Lab Dev Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          kind
          kubectl
          kubernetes-helm
          k9s
          opentofu
          curl
          jq
        ];

        shellHook = ''
          export KUBECONFIG=$PWD/.kube/config
          mkdir -p .kube
          echo "GitOps lab ready"
        '';
      };
    };
}
