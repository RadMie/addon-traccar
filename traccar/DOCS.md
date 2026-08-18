# Traccar 6 for Home Assistant

This unofficial app runs Traccar Server 6.14.5 on Home Assistant OS. It
supports `amd64` and `aarch64` systems.

## Installation

1. Create a full Home Assistant backup.
2. Install and start the official MariaDB app. MariaDB is strongly recommended
   for production installations.
3. Add this repository in **Settings > Apps/Add-ons > App store >
   Repositories**:

   ```text
   https://github.com/RadMie/addon-traccar
   ```

4. Open **Traccar 6 (RadMie)** and select **Install**. The image is built on
   the Home Assistant host and the first installation can take several
   minutes.
5. Configure the app, start it, and inspect its log. The first start can take
   longer while Traccar applies database migrations.
6. Select **Open Web UI** and create or sign in to the Traccar administrator
   account.

## Upgrading from the Community Traccar 5 app

Traccar can migrate a 5.x database directly, but a downgrade after the schema
migration is not safe. Before the first start:

1. Make a full Home Assistant backup and a separate, restorable MariaDB backup.
2. Save the old app's `traccar.xml` if it contains custom protocol or database
   settings. It is normally under
   `/addon_configs/a0d7b954_traccar/traccar.xml`.
3. Stop the old Traccar app. Do not run the old and new apps together; both use
   the same host ports and, with MariaDB, the same `traccar` database.
4. Install this app. Copy the custom entries from the old `traccar.xml` into
   the new app's config folder, whose name also ends in `_traccar` under
   `/addon_configs/`.
5. Start the new app and wait for all database migrations to finish. Confirm
   the version, devices, users, positions, events, and configured protocols.

The obsolete `config.default` entry in an old file is ignored and removed only
from the generated runtime config. The persistent user file is not rewritten.
Old `*.port` protocol entries are automatically included in the Traccar 6
protocol allowlist.

The H2 database is stored in an app-specific `/data` volume. A fork has a
different app identifier, so an H2 database from the Community app is **not**
migrated automatically. Migrate the old installation to MariaDB first or plan
a manual H2 export/import before switching apps.

## App configuration

Restart the app after changing these options.

```yaml
log_level: info
ssl: false
certfile: fullchain.pem
keyfile: privkey.pem
```

- `log_level` controls the Home Assistant app/service log verbosity.
- `ssl` enables HTTPS on the directly exposed web interface.
- `certfile` and `keyfile` name files stored in `/ssl` when SSL is enabled.

By default, the web interface is available on host port `8082`. Traccar itself
listens internally on `127.0.0.1:18682`, behind Nginx.

## Traccar XML configuration

After the first start, the app creates `traccar.xml` in its app config folder:

```text
/addon_configs/<repository-id>_traccar/traccar.xml
```

Add only values that override the managed defaults. The file must remain a
valid Java properties XML document.

Only the OsmAnd protocol is enabled by default. Traccar 6 has built-in default
ports for all protocols, so use `protocols.enable` to list the protocols that
should listen on the host. For example:

```xml
<entry key='protocols.enable'>osmand,teltonika</entry>
<entry key='teltonika.port'>5027</entry>
```

The second line is needed only if you want to override Teltonika's built-in
port. Because the app uses the host network, every enabled protocol opens its
TCP and/or UDP listener directly on the Home Assistant host. Enable only the
protocols you need and configure your firewall accordingly.

Use the [Traccar device/protocol finder][devices] and the
[configuration reference][configuration] to find valid names and options.

If `database.driver` is present in the user file, the app treats all database
entries as a custom database configuration and does not inject MariaDB service
credentials. Otherwise it uses the Home Assistant MariaDB service when
available, or persistent H2 as a fallback.

## Home Assistant integration

Use **Settings > Devices & services > Add integration > Traccar Server**. For
an app running on the same Home Assistant OS host, use the local Traccar URL
and an API token generated in Traccar. Follow the current
[Traccar Server integration documentation][ha-integration] for the fields and
token procedure; the old YAML `device_tracker` setup is obsolete.

## Updating this repository

Home Assistant reads the default Git branch and detects an update when
`version` in `traccar/config.yaml` changes. A GitHub Release is not required
for this locally built app. Refresh the app store after a new version is pushed
to `main`.

[configuration]: https://www.traccar.org/configuration-file/
[devices]: https://www.traccar.org/devices/
[ha-integration]: https://www.home-assistant.io/integrations/traccar_server/
