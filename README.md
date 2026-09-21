# mc-router Pelican Egg

A Pelican Panel egg and Pelican-compatible multi-architecture image for [itzg/mc-router](https://github.com/itzg/mc-router).

`mc-router` routes Minecraft Java Edition connections to backend servers based on the hostname the player entered. This makes it possible to expose several Minecraft servers behind one public IP and one TCP port.

## Design

This repository intentionally puts the `mc-router` executable directly into the runtime image instead of downloading it during every Pelican server installation.

That provides:

- reproducible server starts;
- no dependency on GitHub downloads during Pelican installation or startup;
- one tested image for `linux/amd64` and `linux/arm64`;
- image tags that identify the bundled upstream version;
- automatic rebuilding against the latest upstream release.

The Pelican egg deliberately exposes no mc-router settings as Egg variables. Routing is configured only through `routes.json`.

## Files

- `Dockerfile` — Pelican-compatible runtime image with mc-router preinstalled.
- `entrypoint.sh` — Pelican-compatible container entrypoint.
- `egg-mc-router.json` — importable Pelican Egg.
- `routes.json.example` — example static route configuration.
- `.github/workflows/docker.yml` — resolves the latest upstream release, builds with Buildx and publishes a multi-arch image to GHCR.

## Supported architectures

The published image is built for:

- `linux/amd64`
- `linux/arm64`

## GHCR image

```text
ghcr.io/s3tupw1zard/mc-router-pelican-egg:latest
```

The workflow also publishes version-specific tags such as:

```text
ghcr.io/s3tupw1zard/mc-router-pelican-egg:mc-router-1.47.1
```

and a commit SHA tag.

GitHub Container Registry packages can initially be private depending on account/package settings. Make the package public if Pelican should pull it without registry credentials.

## Import into Pelican

1. Let the `Build and publish image` workflow complete at least once.
2. Make sure the GHCR package is publicly pullable, or configure registry credentials in Wings.
3. Download `egg-mc-router.json` from this repository.
4. Import the Egg in Pelican Admin.
5. Create a server with one TCP allocation. Port `25565` is conventional, but any allocated TCP port works.
6. Edit `routes.json` in the server Files view.
7. Start the server.

The Egg automatically starts mc-router with the Pelican server's primary allocation:

```text
PORT={{SERVER_PORT}} ROUTES_CONFIG="routes.json" ROUTES_CONFIG_WATCH=true /usr/local/bin/mc-router
```

No additional Egg variables are required.

## routes.json

During installation the Egg creates `routes.json.example` if it does not already exist.

If `routes.json` does not exist yet, the installer copies the example file to `routes.json`. Existing `routes.json` files are never overwritten during reinstallations.

The default example is:

```json
{
  "default-server": "",
  "mappings": {
    "smp.example.com": "10.0.0.10:50000",
    "private.example.com": "10.0.0.11:50001"
  }
}
```

The keys in `mappings` are the hostnames players enter in Minecraft. The values are backend `host:port` addresses reachable from the Wings node.

Because route watching is always enabled, changes to `routes.json` are reloaded by mc-router without restarting the Pelican server.

### Default backend

If unmatched hostnames should be sent to a fallback server, set `default-server`:

```json
{
  "default-server": "10.0.0.10:50000",
  "mappings": {
    "smp.example.com": "10.0.0.10:50000"
  }
}
```

Leaving `default-server` empty means there is no fallback backend.

## Private backend networks

Backend addresses do not need to be publicly reachable. They can be private IP addresses or DNS names reachable from the Wings node, including NetBird addresses.

For example:

```json
{
  "default-server": "",
  "mappings": {
    "smp.example.com": "smp.nodes.example.com:50000",
    "private.example.com": "private.nodes.example.com:50001"
  }
}
```

Only the mc-router allocation itself needs to be reachable by Minecraft clients.

## Updating mc-router

The GitHub Actions workflow regularly checks the latest release from `itzg/mc-router` and can also be started manually.

The image build downloads the matching upstream Linux archive and verifies it against the upstream checksum file before copying the binary into the final Pelican runtime image.

Because the Egg uses the `:latest` image by default, pulling the image again can move the server to a newer bundled mc-router version. Version-specific GHCR tags are also published for controlled deployments.

## Docker discovery

`mc-router` supports Docker-based discovery upstream, but this Egg intentionally does not expose the Wings Docker socket.

Static `routes.json` mappings are used instead. This keeps the Pelican container isolated from the host Docker daemon and is the intended deployment model for this Egg.

## Local image build

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg MC_ROUTER_VERSION=1.47.1 \
  -t ghcr.io/s3tupw1zard/mc-router-pelican-egg:test \
  .
```

For a local single-architecture test:

```bash
docker build \
  --build-arg MC_ROUTER_VERSION=1.47.1 \
  -t mc-router-pelican:test \
  .
```

## Upstream

- mc-router: https://github.com/itzg/mc-router
- Pelican Panel: https://pelican.dev/
- Pelican Eggs: https://github.com/pelican-eggs

This project is an integration package and is not affiliated with the upstream mc-router or Pelican projects.
