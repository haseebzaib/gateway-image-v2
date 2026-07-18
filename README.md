# MetaCrust Gateway Image v2

This is the image tree for the MetaCrust gateway runtime.

The image should stay boring:

- Build the Raspberry Pi OS image.
- Install runtime packages.
- Create `/opt/metacrust`.
- Enable board hardware support.
- Keep Tailscale available independently from gateway services.
- Apply Ethernet, Wi-Fi, access-point, and cellular configuration.
- Monitor uplink health and perform priority-based failover and recovery.
- Publish network state as JSON for `gateway_hub` to consume later.
- Grow CM5 normal-image root filesystem to fill eMMC.

Network runtime policy currently remains in the image scripts. This preserves the
already-tested implementation while `gateway_hub` integration is completed.

## Runtime Layout

```text
/opt/metacrust/scripts       shell actuator scripts
/opt/metacrust/gateway_core  future C++ application
/opt/metacrust/gateway_hub   future Python application
/opt/metacrust/config        persistent application configuration
/opt/metacrust/state         persistent runtime state
/opt/metacrust/data          persistent application data
/opt/metacrust/log           persistent logs
/opt/metacrust/secrets       device secrets, including tailscale.env
```

## Network Runtime

The network configuration is persisted at:

```text
/opt/metacrust/config/network/config.json
```

If it is missing or invalid, `gateway-network-apply` restores the immutable
defaults from `/usr/share/metacrust/network/defaults.json`. Runtime JSON is
written under `/opt/metacrust/state/network/`:

```text
state.json
apply-result.json
uplink-stats.json
monitor-state.json
recovery-state.json
cellular-state.json
cellular-retry-state.json
tailscale-recovery-state.json
```

Useful device commands:

```bash
sudo systemctl status gateway-network-apply gateway-network-monitor
sudo /opt/metacrust/scripts/gateway-networkctl state
sudo /opt/metacrust/scripts/gateway-networkctl result
sudo /opt/metacrust/scripts/gateway-networkctl scan-wifi
sudo /opt/metacrust/scripts/gateway-networkctl apply
```

The service and command names intentionally retain the `gateway-network-*`
contract used by the existing Connectivity UI.

## Build

From `gateway_prj/rpi-image-gen`:

```bash
./rpi-image-gen build -S ./gateway-image-v2 -c cm5-dev.yaml
```

For Raspberry Pi 4 Model B testing:

```bash
./rpi-image-gen build -S ./gateway-image-v2 -c pi4-dev.yaml
```

Optional A/B OTA image, for later:

```bash
./rpi-image-gen build -S ./gateway-image-v2 -c cm5-ab-ota.yaml -- IGconf_connect_authkey=rpuak_XXX
```

Tailscale is configured separately through:

```text
/opt/metacrust/secrets/tailscale.env
```

Set `TS_AUTHKEY` there on the device or bake a deployment-specific secret file
before building.

## Remote Update Direction

`cm5-dev.yaml` is intentionally simple and does not use A/B by default.
`cm5-ab-ota.yaml` keeps the A/B + Raspberry Pi Connect OTA provisioning for
later full-image update testing.

Tailscale remains standalone and should be treated as the emergency access path.
