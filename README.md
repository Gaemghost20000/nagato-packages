# Nagato Packages

Package build environment for the [Nagato Agent](https://github.com/Gaemghost20000/nagato-android) Android app.

Forked from [termux/termux-packages](https://github.com/termux/termux-packages) with custom package prefix `com.nagato.agent`.

## Key Change

`scripts/properties.sh`:
```bash
TERMUX_APP__PACKAGE_NAME="com.nagato.agent"
```

All packages built from this repository have `/data/data/com.nagato.agent/files/usr` hardcoded as `$PREFIX`.

## Build

```bash
# Requires Docker
docker run --rm --privileged \
    -v $(pwd):/home/builder/termux-packages \
    termux/package-builder:latest \
    bash -c "./scripts/build-bootstraps.sh --architectures aarch64"

# Output: bootstrap-aarch64.zip
```

## Docs

- [PROPERTIES_PATCH.md](docs/PROPERTIES_PATCH.md) — Which variables to change
