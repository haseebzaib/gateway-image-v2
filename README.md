# MetaCrust Gateway Image v2

This is the clean image tree for the new gateway architecture.

The image should stay boring:

- Build the Raspberry Pi OS image.
- Install runtime packages.
- Create `/opt/metacrust`.
- Enable board hardware support.
- Keep Tailscale available independently from gateway services.
- Bring Ethernet, Wi-Fi, cellular interfaces, and standard managers up.
- Provide small privileged actuator scripts for `gateway_core`.

The image should not own runtime policy. Network monitoring, uplink selection,
anomaly detection, history, and recovery decisions belong in `gateway_core`.

## Runtime Layout

```text
/opt/metacrust/bin        executables and actuator scripts
/opt/metacrust/etc        default/static config shipped in image
/opt/metacrust/state      runtime state target for future gateway_core
/opt/metacrust/log        log target for future gateway_core
/opt/metacrust/secrets    device secrets, including tailscale.env
/persistent/metacrust     persistent backing store when persistent partition exists
```

## Build

From `gateway_prj/rpi-image-gen`:

```bash
./rpi-image-gen build -S ./gateway-image-v2 -c cm5-dev.yaml
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
