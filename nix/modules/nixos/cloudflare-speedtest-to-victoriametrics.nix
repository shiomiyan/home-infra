{ pkgs, inputs, ... }:

let
  package = pkgs.callPackage ../../packages/cloudflare-speedtest-to-victoriametrics {
    inherit inputs;
  };
in
{
  systemd.services.cloudflare-speedtest-to-victoriametrics = {
    description = "Send Cloudflare speed test metrics to VictoriaMetrics";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${package}/bin/cloudflare-speedtest-to-victoriametrics";
      User = "pi";
      Group = "pi";
    };
  };

  systemd.timers.cloudflare-speedtest-to-victoriametrics = {
    description = "Run Cloudflare speed test every 15 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* *:00/15:00";
      AccuracySec = "1s";
      Persistent = true;
      Unit = "cloudflare-speedtest-to-victoriametrics.service";
    };
  };
}
