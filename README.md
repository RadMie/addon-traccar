# Traccar 6 for Home Assistant

An unofficial Home Assistant app (add-on) repository containing Traccar
Server 6.14.5. It is based on the original
[Home Assistant Community Traccar add-on][upstream-addon].

![Supports aarch64][aarch64-shield]
![Supports amd64][amd64-shield]

![Traccar in the Home Assistant frontend](images/screenshot.png)

## Install

[![Add this repository to Home Assistant][repository-badge]][repository-add]

Or add this URL manually in **Settings > Apps/Add-ons > App store >
Repositories**:

```text
https://github.com/RadMie/addon-traccar
```

Open **Traccar 6 (RadMie)** in the store and select **Install**. Home Assistant
builds the container locally from the default branch, so a GitHub Release is
not required. The first installation can take several minutes.

The MariaDB app is strongly recommended. H2 is available only as a fallback
and is not recommended by the Traccar project for production.

See [the full app documentation](traccar/DOCS.md) before upgrading an existing
Traccar 5 installation. The database migration is one-way unless you restore a
backup, and the old and new apps must never run at the same time.

## Development branches

Home Assistant can install a specific branch by appending `#branch-name` to
the repository URL. For example:

```text
https://github.com/RadMie/addon-traccar#renovate/traccar-traccar-6.x
```

For normal use, merge tested changes into the default `main` branch and use
the URL without a branch suffix. App updates are detected from the `version`
field in `traccar/config.yaml`, not from GitHub Releases.

## Credits and license

The add-on was originally created and maintained by Franck Nijhof and the
Home Assistant Community Add-ons contributors. Traccar is maintained by the
[Traccar project][traccar]. This repository retains the original MIT license.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[repository-add]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FRadMie%2Faddon-traccar
[repository-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[traccar]: https://www.traccar.org
[upstream-addon]: https://github.com/hassio-addons/addon-traccar
