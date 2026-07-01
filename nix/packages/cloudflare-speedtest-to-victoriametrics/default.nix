{ pkgs, inputs, ... }:

let
  script = ''
    set -euo pipefail

    vm_write_url="http://127.0.0.1:8428/api/v1/import/prometheus"

    metrics_payload="$(
      cloudflare-speed-cli --json --auto-save false | jq -er '
        def labels:
          "{source=\"cloudflare_speedtest\"" +
          ",interface_name=\"" + (.interface_name | tostring) + "\"" +
          ",is_wireless=\"" + (.is_wireless | tostring) + "\"" +
          ",asn=\"" + (.asn | tostring) + "\"}";

        [
          "cf_speed_download_mbps" + labels + " " + (.download.mbps | tostring),
          "cf_speed_upload_mbps" + labels + " " + (.upload.mbps | tostring),
          "cf_speed_idle_latency_mean_ms" + labels + " " + (.idle_latency.mean_ms | tostring),
          "cf_speed_idle_latency_jitter_ms" + labels + " " + (.idle_latency.jitter_ms | tostring),
          "cf_speed_loaded_latency_download_mean_ms" + labels + " " + (.loaded_latency_download.mean_ms | tostring),
          "cf_speed_loaded_latency_upload_mean_ms" + labels + " " + (.loaded_latency_upload.mean_ms | tostring),
          "cf_speed_bufferbloat_ms" + labels + " " + (.connection_quality.bufferbloat_ms | tostring)
        ] | join("\n")
      '
    )"

    curl \
      --fail \
      --show-error \
      --silent \
      -H "Content-Type: text/plain; version=0.0.4" \
      --data-binary @- \
      "$vm_write_url" <<<"$metrics_payload"
  '';
in
pkgs.writeShellApplication {
  name = "cloudflare-speedtest-to-victoriametrics";
  runtimeInputs = [
    inputs.cloudflare-speed-cli.packages.${pkgs.system}.default
    pkgs.curl
    pkgs.jq
  ];
  text = script;
}
