#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Traccar
# Builds a Traccar 6 compatible runtime configuration
# ==============================================================================
readonly DEFAULT_CONFIG="/etc/traccar/hassio.xml"
readonly LEGACY_CONFIG="/homeassistant/traccar.xml"
readonly RUNTIME_CONFIG="/run/traccar.xml"
readonly USER_CONFIG="/config/traccar.xml"

umask 077

declare host
declare key
declare password
declare port
declare protocol
declare protocols
declare runtime_config
declare structure_error_count
declare username
declare url
declare value

entry_exists() {
    local file="${1}"
    local key="${2}"
    local count

    count=$(xmlstarlet sel -t -v \
        "count(/properties/entry[@key='${key}'])" "${file}" 2>/dev/null)
    (( count > 0 ))
}

set_entry() {
    local file="${1}"
    local key="${2}"
    local output
    local value="${3}"

    output=$(mktemp "${file}.XXXXXX")
    if ! xmlstarlet tr /etc/traccar/set-entry.xsl \
        -s "key=${key}" -s "value=${value}" "${file}" \
        > "${output}" 2>/dev/null; then
        rm -f -- "${output}"
        bashio::exit.nok "Failed to set ${key} in the runtime configuration"
    fi
    chmod 600 "${output}"
    mv -f -- "${output}" "${file}"
}

# Migrate add-on data from the Home Assistant config folder,
# to the add-on configuration folder.
if ! bashio::fs.file_exists "${USER_CONFIG}" \
    && bashio::fs.file_exists "${LEGACY_CONFIG}"; then
    cp "${LEGACY_CONFIG}" "${USER_CONFIG}" \
        || bashio::exit.nok "Failed to migrate Traccar configuration"
fi

if ! bashio::fs.file_exists "${USER_CONFIG}"; then
    cp /etc/traccar/traccar.xml "${USER_CONFIG}"
fi

if ! xmlstarlet val -e "${USER_CONFIG}" >/dev/null 2>&1 \
    || [[ "$(xmlstarlet sel -t -v 'name(/*)' "${USER_CONFIG}" 2>/dev/null)" != "properties" ]]; then
    bashio::exit.nok "Traccar configuration is not a valid Java properties XML file"
fi

structure_error_count=$(xmlstarlet sel -t -v \
    "count(/properties/*[not(self::entry or self::comment)] | /properties/entry[not(@key)])" \
    "${USER_CONFIG}" 2>/dev/null)
if (( structure_error_count > 0 )); then
    bashio::exit.nok "Traccar configuration contains invalid properties XML elements"
fi

# Traccar 6.2 removed config.default. Keep the user's file unchanged and merge
# the Home Assistant defaults into an ephemeral runtime configuration instead.
runtime_config=$(mktemp /run/traccar.XXXXXX)
trap 'rm -f -- "${runtime_config}"' EXIT
cp "${USER_CONFIG}" "${runtime_config}"
if ! xmlstarlet ed -L \
    -d "/properties/entry[@key='config.default']" \
    "${runtime_config}" 2>/dev/null; then
    bashio::exit.nok "Failed to remove config.default from runtime configuration"
fi

while IFS= read -r key; do
    if ! entry_exists "${runtime_config}" "${key}"; then
        value=$(xmlstarlet sel -t -v \
            "/properties/entry[@key='${key}'][1]" \
            "${DEFAULT_CONFIG}" 2>/dev/null)
        set_entry "${runtime_config}" "${key}" "${value}"
    fi
done < <(xmlstarlet sel -t -m "/properties/entry[@key]" \
    -v "@key" -n "${DEFAULT_CONFIG}" 2>/dev/null)

# Older add-on versions enabled protocols by adding a *.port entry. Traccar 6
# has built-in ports for every protocol, so it now needs an explicit allowlist.
# Preserve old custom protocol entries while keeping all other listeners closed.
if ! entry_exists "${USER_CONFIG}" "protocols.enable"; then
    protocols="osmand"
    while IFS= read -r key; do
        protocol="${key%.port}"
        case "${protocol}" in
            osmand|web|mail.smtp|broadcast)
                continue
                ;;
        esac
        if [[ ",${protocols}," != *",${protocol},"* ]]; then
            protocols+=",${protocol}"
        fi
    done < <(xmlstarlet sel -t \
        -m "/properties/entry[substring(@key, string-length(@key) - 4) = '.port']" \
        -v "@key" -n "${USER_CONFIG}" 2>/dev/null)
    set_entry "${runtime_config}" "protocols.enable" "${protocols}"
fi

mkdir -p /data/media

# Respect a custom database configured by the user. Otherwise use the
# Supervisor-provided MariaDB service, with H2 as a development fallback.
if entry_exists "${USER_CONFIG}" "database.driver"; then
    if ! entry_exists "${USER_CONFIG}" "database.url"; then
        bashio::exit.nok \
            "Custom database.driver requires database.url in traccar.xml"
    fi

    # Do not let H2 fallback credentials leak into a custom database config.
    for key in database.user database.password; do
        if ! entry_exists "${USER_CONFIG}" "${key}"; then
            xmlstarlet ed -L \
                -d "/properties/entry[@key='${key}']" \
                "${runtime_config}" 2>/dev/null
        fi
    done
    bashio::log.info "Using the custom database from traccar.xml"
elif entry_exists "${USER_CONFIG}" "database.url" \
    || entry_exists "${USER_CONFIG}" "database.user" \
    || entry_exists "${USER_CONFIG}" "database.password"; then
    bashio::exit.nok \
        "Incomplete custom database settings: add database.driver and database.url"
elif bashio::services.available "mysql"; then
    host=$(bashio::services "mysql" "host")
    password=$(bashio::services "mysql" "password")
    port=$(bashio::services "mysql" "port")
    username=$(bashio::services "mysql" "username")

    bashio::net.wait_for "${port}" "${host}" 300
    if ! MYSQL_PWD="${password}" mysql --skip-ssl \
        --connect-timeout=10 \
        -h "${host}" -P "${port}" -u "${username}" \
        -e "CREATE DATABASE IF NOT EXISTS traccar;"; then
        bashio::exit.nok "Failed to initialize the Traccar MariaDB database"
    fi

    url="jdbc:mysql://${host}:${port}/traccar?zeroDateTimeBehavior=round&serverTimezone=UTC&allowPublicKeyRetrieval=true&useSSL=false&allowMultiQueries=true&autoReconnect=true&useUnicode=yes&characterEncoding=UTF-8&sessionVariables=sql_mode=''"
    set_entry "${runtime_config}" "database.driver" \
        "com.mysql.cj.jdbc.Driver"
    set_entry "${runtime_config}" "database.url" "${url}"
    set_entry "${runtime_config}" "database.user" "${username}"
    set_entry "${runtime_config}" "database.password" "${password}"
else
    bashio::log.warning "Traccar is using the internal H2 database."
    bashio::log.warning "H2 is not recommended for production; install MariaDB."
fi

for key in database.driver database.url; do
    if ! entry_exists "${runtime_config}" "${key}"; then
        bashio::exit.nok "Generated Traccar configuration is missing ${key}"
    fi
    value=$(xmlstarlet sel -T -t -v \
        "/properties/entry[@key='${key}'][last()]" \
        "${runtime_config}" 2>/dev/null)
    if [[ -z "${value//[[:space:]]/}" ]]; then
        bashio::exit.nok "Generated Traccar configuration has an empty ${key}"
    fi
done

value=$(xmlstarlet sel -T -t -v \
    "/properties/entry[@key='web.port'][last()]" \
    "${runtime_config}" 2>/dev/null)
if [[ ! "${value}" =~ ^[0-9]+$ ]] \
    || (( 10#${value} < 1 || 10#${value} > 65535 )); then
    bashio::exit.nok "Generated Traccar configuration has an invalid web.port"
fi

if entry_exists "${runtime_config}" "config.default"; then
    bashio::exit.nok "Failed to remove obsolete config.default setting"
fi

chmod 600 "${runtime_config}"
mv -f -- "${runtime_config}" "${RUNTIME_CONFIG}"
trap - EXIT
