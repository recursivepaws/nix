{
  den.aspects.kubernetes = {
    nixos =
      { pkgs, ... }:
      {

        environment.systemPackages = with pkgs; [
          kubectl
          kubernetes
        ];
      };
    homeManager =
      {
        pkgs,
        config,
        lib,
        ...
      }:

      let
        tailscaleDomain = "fox-diatonic.ts.net";
        clusters = [
          # AWS
          {
            cloud = "aws";
            region = "us-east-1";
            clusterName = "production-us-east-1-eks";
          }
          {
            cloud = "aws";
            region = "eu-west-1";
            clusterName = "production-eu-west-1-eks";
          }
          {
            cloud = "aws";
            region = "ap-south-1";
            clusterName = "production-ap-south-1-eks";
          }
          {
            cloud = "aws";
            region = "us-west-2";
            clusterName = "production-us-west-2-eks";
          }
          {
            cloud = "aws";
            region = "ap-southeast-2";
            clusterName = "production-ap-southeast-2-eks";
          }
          # GCP
          {
            cloud = "gcp";
            region = "us-east4";
            clusterName = "hightouch-production-gcp-us-east4";
          }
          {
            cloud = "gcp";
            region = "europe-west1";
            clusterName = "hightouch-production-gcp-europe-west1";
          }
          {
            cloud = "gcp";
            region = "me-central2";
            clusterName = "hightouch-production-gcp-me-central2";
          }
          # Azure
          {
            cloud = "azure";
            region = "eastus";
            clusterName = "hightouch-production-azure-eastus-cluster";
          }
        ];

        # Build the kubeconfig attrset in pure Nix
        kubeconfigAttrs = {
          apiVersion = "v1";
          kind = "Config";
          current-context = "prod-${(builtins.head clusters).cloud}-${(builtins.head clusters).region}";
          users = [
            {
              name = "tailscale-user";
              user.username = "tailscale-user";
            }
          ];
          clusters = map (c: {
            name = "prod-${c.cloud}-${c.region}";
            cluster.server = "https://tailscale-operator-${c.cloud}-${c.region}.${tailscaleDomain}";
          }) clusters;
          contexts = map (c: {
            name = "prod-${c.cloud}-${c.region}";
            context = {
              cluster = "prod-${c.cloud}-${c.region}";
              user = "tailscale-user";
            };
          }) clusters;
          preferences = { };
        };

        # Render to YAML using pkgs.formats.yaml
        kubeconfigYaml = (pkgs.formats.yaml { }).generate "kubeconfig" kubeconfigAttrs;

        # Script to merge generated config into existing ~/.kube/config
        mergeKubeconfig = pkgs.writeShellApplication {
          name = "merge-hightouch-kubeconfig";
          runtimeInputs = [ pkgs.kubectl ];
          text = ''
            set -euo pipefail
            KUBECONFIG_PATH="''${KUBECONFIG:-$HOME/.kube/config}"
            mkdir -p "$(dirname "$KUBECONFIG_PATH")"

            if [ -f "$KUBECONFIG_PATH" ]; then
              # Merge: existing config wins for current-context, new clusters/contexts/users are upserted
              KUBECONFIG="$KUBECONFIG_PATH:${kubeconfigYaml}" \
                kubectl config view --flatten > "$KUBECONFIG_PATH.tmp"
              mv "$KUBECONFIG_PATH.tmp" "$KUBECONFIG_PATH"
            else
              cp ${kubeconfigYaml} "$KUBECONFIG_PATH"
              chmod 600 "$KUBECONFIG_PATH"
            fi

            echo "Wrote kubeconfig to $KUBECONFIG_PATH"
          '';
        };
      in

      {
        home = {
          packages = [ mergeKubeconfig ];
          # Run the merge on every home-manager activation
          activation.mergeHightouchKubeconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD ${mergeKubeconfig}/bin/merge-hightouch-kubeconfig
          '';
        };
      };
  };
}
