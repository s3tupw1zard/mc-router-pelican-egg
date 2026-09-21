# mc-router Pelican Egg

A Pelican Panel egg and Pelican-compatible multi-architecture image for [itzg/mc-router](https://github.com/itzg/mc-router).

`mc-router` routes Minecraft Java Edition connections to backend servers based on the hostname the player entered. This makes it possible to expose several Minecraft servers behind one public IP and one TCP port.

## Design

This repository intentionally puts the `mc-router` executable in the runtime image instead of downloading it during every Pelican server installation.

That gives a few useful properties:

- reproducible server starts;
- no dependency on GitHub downloads during Pelican installation or startup;
- one tested image for `linux/amd64` and `linux/arm64`;
- image tags that identify the bundled upstream version;
- automatic rebuilding against the latest upstream release.

The Pelican installation script only creates a starter `routes.json` when it does not already exist.

## Files

- `Dockerfile` — Pelican-compatible runtime image.
- `entrypoint.sh` — expands Pelican's startup variables and launches the configured command under `tini`.
- `egg-mc-router.json` — importable Pelican egg.
- `routes.example.json` — example static route configuration.
- `.github/workflows/docker.yml` — resolves the latest upstream release, builds with Buildx and publishes a multi-arch image to GHCR.

## Supported architectures

The published image is built for:

- `linux/amd64`
- `linux/arm64`

## GHCR image

```text
ghcr.io/s3tupw1zard/mc-router-pelican-egg:latest
```

The workflow also publishes version-oriented tags such as:

```text
ghcr.io/s3tupw1zard/mc-router-pelican-egg:mc-router-1.47.1
```

and a commit SHA tag.

### First GHCR publish

GitHub Container Registry packages can initially be private depending on account/package settings. After the first successful workflow run, open the package settings and set the package visibility to **Public** if Pelican should pull it without registry credentials.

## Import into Pelican

1. Let the `Build and publish image` workflow complete at least once.
2. Make sure the GHCR package is publicly pullable, or configure registry credentials in Wings.
3. Download `egg-mc-router.json` from this repository.
4. In Pelican Admin, import the egg.
5. Create a server with one TCP allocation. Port `25565` is conventional, but any allocated TCP port works.
6. Edit `routes.json` in the server Files view.
7. Start the server.

Pelican substitutes the server's primary allocation into `SERVER_PORT`, and the egg starts `mc-router` on that port.

## Recommended configuration: routes.json

The recommended startup command is **Routes file (recommended)**.

A minimal configuration is:

```json
{
  "default-server": "",
  "mappings": {
    "smp.example.com": "10.0.0.10:50000",
    "private.example.com": "10.0.0.11:50001"
  }
}
```

The keys are the hostnames players enter in Minecraft. The values are backend `host:port` targets reachable from the Wings node.

With `ROUTES_CONFIG_WATCH=true`, `mc-router` watches the file and reloads it after changes.

### Default server

Set `default-server` if unmatched hostnames should be sent somewhere:

```json
{
  "default-server": "10.0.0.10:50000",
  "mappings": {
    "smp.example.com": "10.0.0.10:50000"
  }
}
```

Leaving it empty means an unmapped hostname has no fallback backend.

## Alternative: MAPPING environment variable

The egg also contains an **Environment mappings** startup command.

Example `MAPPING` value:

```text
smp.example.com=10.0.0.10:50000,private.example.com=10.0.0.11:50001
```

Newline-separated mappings also work.

Do not combine watched `routes.json` mappings with `MAPPING`. `mc-router` initially loads the routes file and then adds environment mappings, but a later routes-file reload resets the route table and rebuilds it from the file. Use one configuration method consistently.

## NetBird / private backend networks

The backend addresses do not need to be publicly reachable. If the Wings host can reach the backend servers over NetBird, the values in `routes.json` can be NetBird DNS names or NetBird IPs, for example:

```json
{
  "default-server": "",
  "mappings": {
    "smp.example.com": "smp.nodes.example.com:50000",
    "private.example.com": "private.nodes.example.com:50001"
  }
}
```

Only the `mc-router` allocation needs to be exposed to Minecraft clients.

## PROXY protocol

The egg exposes the main `mc-router` PROXY protocol options:

- `USE_PROXY_PROTOCOL`
- `RECEIVE_PROXY_PROTOCOL`
- `DYNAMIC_PROXY_PROTOCOL`
- `TRUSTED_PROXIES`

`DYNAMIC_PROXY_PROTOCOL` cannot be enabled together with `USE_PROXY_PROTOCOL` or `RECEIVE_PROXY_PROTOCOL`.

Only enable PROXY protocol toward a backend that is explicitly configured to understand it.

## Client filtering and rate limiting

Available variables include:

- `CONNECTION_RATE_LIMIT`
- `CLIENTS_TO_ALLOW`
- `CLIENTS_TO_DENY`
- `RECORD_LOGINS`
- `LOG_LEVEL`

The default rate limit in this egg is `10` connections per second. Adjust it for your environment.

## Updating mc-router

The GitHub Actions workflow runs daily and resolves the latest release from `itzg/mc-router`. It also runs whenever the Dockerfile, entrypoint, or workflow changes.

You can manually start the workflow and optionally provide a specific version such as:

```text
1.47.1
```

The image build downloads the matching Linux archive from the upstream GitHub release and verifies it against the upstream checksum file before copying the binary into the final Pelican runtime image.

Because the egg uses the `:latest` image by default, a server recreation/pull can move to a newer bundled mc-router version. If you prefer controlled updates, edit the egg/image selection to a version tag such as `:mc-router-1.47.1`.

## Why not Docker discovery?

`mc-router` supports Docker discovery by accessing the Docker socket. This egg intentionally does not expose `/var/run/docker.sock` to the Pelican server container.

Giving a game-server container access to the Wings host Docker socket would grant far more control over the host than is needed for ordinary static routing. For Pelican deployments, static `routes.json` mappings are the safer default.

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
