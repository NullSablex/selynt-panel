#!/bin/sh
# ols-paths.sh — Detect the OpenLiteSpeed layout.
#
# DA 1.690+ (via CustomBuild) moves the configuration from
# /usr/local/lsws/conf to /etc/openlitespeed and the admin logs to
# /var/log/openlitespeed. We keep compatibility with older installs.
#
# Exports:
#   OLS_PRESENT    "1" if OLS was detected, "0" otherwise
#   OLS_CONF_DIR   effective directory of httpd_config.conf
#   OLS_MAIN_CONF  full path to httpd_config.conf
#   OLS_LAYOUT     "new" (/etc/openlitespeed) or "legacy" (/usr/local/lsws/conf)
#
# Usage:
#   . "$(dirname "$0")/lib/ols-paths.sh"
#   selynt_detect_ols
#   echo "$OLS_MAIN_CONF"

selynt_detect_ols() {
    OLS_PRESENT=0
    OLS_LAYOUT=""
    OLS_CONF_DIR=""
    OLS_MAIN_CONF=""

    # Preferred: new layout (DA 1.690+).
    if [ -f /etc/openlitespeed/httpd_config.conf ]; then
        OLS_PRESENT=1
        OLS_LAYOUT="new"
        OLS_CONF_DIR="/etc/openlitespeed"
        OLS_MAIN_CONF="/etc/openlitespeed/httpd_config.conf"
        return 0
    fi

    # Fallback: legacy layout.
    if [ -f /usr/local/lsws/conf/httpd_config.conf ]; then
        OLS_PRESENT=1
        OLS_LAYOUT="legacy"
        OLS_CONF_DIR="/usr/local/lsws/conf"
        OLS_MAIN_CONF="/usr/local/lsws/conf/httpd_config.conf"
        return 0
    fi

    # OLS present but no config detected yet (rare, e.g. mid-install) — still
    # report presence so setup-ols can take action.
    if [ -d /etc/openlitespeed ] || [ -d /usr/local/lsws ]; then
        OLS_PRESENT=1
        if [ -d /etc/openlitespeed ]; then
            OLS_LAYOUT="new"
            OLS_CONF_DIR="/etc/openlitespeed"
        else
            OLS_LAYOUT="legacy"
            OLS_CONF_DIR="/usr/local/lsws/conf"
        fi
        OLS_MAIN_CONF="$OLS_CONF_DIR/httpd_config.conf"
        return 0
    fi

    return 1
}

# Graceful OLS restart — works on both layouts (same systemd unit name).
selynt_ols_restart() {
    if systemctl restart lsws 2>/dev/null; then
        return 0
    fi
    if command -v lswsctrl >/dev/null 2>&1 && lswsctrl restart 2>/dev/null; then
        return 0
    fi
    return 1
}
