Title: Version 1.693 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.693.html

Markdown Content:
Released: 2026-01-19

*   [Drag and drop in empty directories evolution new](https://docs.directadmin.com/changelog/version-1.693.html#drag-and-drop-in-empty-directories)
*   [Context menu in empty directories evolution new](https://docs.directadmin.com/changelog/version-1.693.html#context-menu-in-empty-directories)
*   [File Manager "Restore" and "Delete permanently" actions upgrade evolution update](https://docs.directadmin.com/changelog/version-1.693.html#file-manager-restore-and-delete-permanently-actions-upgrade)
*   [File Manager folder tree internal upgrade evolution update](https://docs.directadmin.com/changelog/version-1.693.html#file-manager-folder-tree-internal-upgrade)
*   [File Manager file editor API endpoint upgrade evolution update](https://docs.directadmin.com/changelog/version-1.693.html#file-manager-file-editor-api-endpoint-upgrade)
*   [File Manager "Save File" and "Save File As" actions upgrade evolution update](https://docs.directadmin.com/changelog/version-1.693.html#file-manager-save-file-and-save-file-as-actions-upgrade)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.693.html#software-version-changes)
*   [More strict default value for CustomBuild phpmyadmin_public setting custombuild update](https://docs.directadmin.com/changelog/version-1.693.html#more-strict-default-value-for-custombuild-phpmyadmin-public-setting)
*   [New OpenLiteSpeed Modsecurity and OpenLiteSpeed global logs location custombuild update](https://docs.directadmin.com/changelog/version-1.693.html#new-openlitespeed-modsecurity-and-openlitespeed-global-logs-location)
*   [Increased default maximum username length update](https://docs.directadmin.com/changelog/version-1.693.html#increased-default-maximum-username-length)
*   [Improved email forwarders loop handling in the Exim configuration update](https://docs.directadmin.com/changelog/version-1.693.html#improved-email-forwarders-loop-handling-in-the-exim-configuration)
*   [Default MySQL/MariaDB UNIX socket path is /run/mysql/mysql.sock update](https://docs.directadmin.com/changelog/version-1.693.html#default-mysql-mariadb-unix-socket-path-is-run-mysql-mysql-sock)
*   [Extended letsencrypt.sh script update](https://docs.directadmin.com/changelog/version-1.693.html#extended-letsencrypt-sh-script)
*   [Inconsistent or faulty checkbox styling evolution fix](https://docs.directadmin.com/changelog/version-1.693.html#inconsistent-or-faulty-checkbox-styling)
*   [Web server template token NGINX_MOD_SECURITY_ENABLE is removed removal](https://docs.directadmin.com/changelog/version-1.693.html#web-server-template-token-nginx-mod-security-enable-is-removed)
*   [CustomBuild no longer supports installing MySQL 5.7 and MariaDB 10.3 removal](https://docs.directadmin.com/changelog/version-1.693.html#custombuild-no-longer-supports-installing-mysql-5-7-and-mariadb-10-3)
*   [Removed use_syslogd configuration option from directadmin.conf removal](https://docs.directadmin.com/changelog/version-1.693.html#removed-use-syslogd-configuration-option-from-directadmin-conf)
*   [Removed rotate_httpd_error_log_global configuration options from directadmin.conf removal](https://docs.directadmin.com/changelog/version-1.693.html#removed-rotate-httpd-error-log-global-configuration-options-from-directadmin-conf)
*   [Removed service_memory_usage.sh script removal](https://docs.directadmin.com/changelog/version-1.693.html#removed-service-memory-usage-sh-script)

## Drag and drop in empty directories evolution new[​](https://docs.directadmin.com/changelog/version-1.693.html#drag-and-drop-in-empty-directories)

Drag and drop functionality is now available in empty directories, working identically to other non-empty directories in the File Manager.

## Context menu in empty directories evolution new[​](https://docs.directadmin.com/changelog/version-1.693.html#context-menu-in-empty-directories)

Context menu with `New Folder`, `New File`, `Upload`, and `Reload` actions is now available in empty directories.

## File Manager "Restore" and "Delete permanently" actions upgrade evolution update[​](https://docs.directadmin.com/changelog/version-1.693.html#file-manager-restore-and-delete-permanently-actions-upgrade)

The File Manager's `Restore` and `Delete permanently` actions in the trash directory now use new API endpoints. Request processing and error management have been upgraded as well. Error notifications appear in the bottom right corner of the window if any error occurs during action processing.

## File Manager folder tree internal upgrade evolution update[​](https://docs.directadmin.com/changelog/version-1.693.html#file-manager-folder-tree-internal-upgrade)

The File Manager's folder tree structure has been refactored for improved internal management. This resolves previous issues, particularly with the `Move` and `Copy` actions.

## File Manager file editor API endpoint upgrade evolution update[​](https://docs.directadmin.com/changelog/version-1.693.html#file-manager-file-editor-api-endpoint-upgrade)

The File Manager's file editor now uses a new API endpoint for loading files.

## File Manager "Save File" and "Save File As" actions upgrade evolution update[​](https://docs.directadmin.com/changelog/version-1.693.html#file-manager-save-file-and-save-file-as-actions-upgrade)

The `Save File` and `Save File As` actions in the File Manager's file editor now use new API endpoints. Note that this may alter file timestamps, permissions, and owner values because the implementation overwrites the original file with a new one. A future update will address this behavior to preserve file metadata.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.693.html#software-version-changes)

*   **lego** updated from `4.23.1-SNAPSHOT-3f6293fe` to `4.31.0-SNAPSHOT-a0eae4e3`
*   **litespeed** updated from `6.3.4-8` to `6.3.4-10`
*   **mod_lsapi** updated from `1.1-86` to `1.1-87`
*   **ModSecurity** rules from **OWASP CRS** updated from `4.21.0` to `4.22.0`
*   **ngx_cache_purge** updated from `2.5.4` to `2.5.5`
*   **openlitespeed** updated from `1.8.4.1` to `1.8.5`
*   **PHP 8.3** updated from `8.3.29` to `8.3.30`
*   **PHP 8.4** updated from `8.4.16` to `8.4.17`
*   **PHP 8.5** updated from `8.5.1` to `8.5.2`
*   **pureftpd** updated from `1.0.52` to `1.0.53`
*   **snuffleupagus** (PHP extension) updated from `0.12.0` to `0.13.0`

## More strict default value for CustomBuild `phpmyadmin_public` setting custombuild update[​](https://docs.directadmin.com/changelog/version-1.693.html#more-strict-default-value-for-custombuild-phpmyadmin-public-setting)

Default setting for the phpmyadmin_public in custombuild is now "no", which allows to login users via directadmin panel only.

## New OpenLiteSpeed Modsecurity and OpenLiteSpeed global logs location custombuild update[​](https://docs.directadmin.com/changelog/version-1.693.html#new-openlitespeed-modsecurity-and-openlitespeed-global-logs-location)

ModSecurity and global OpenLiteSpeed logs are now located in `/var/log/openlitespeed` directory. The admin panel logs are renamed to `admin-access.log` and `admin-error.log`. This solves the duplicate log error in logrotate between the webservers and gives a cleaner structure.

## Increased default maximum username length update[​](https://docs.directadmin.com/changelog/version-1.693.html#increased-default-maximum-username-length)

The default value for maximum allowed username length (`max_username_length` option) is increased from 10 symbols to 16 symbols.

## Improved email forwarders loop handling in the Exim configuration update[​](https://docs.directadmin.com/changelog/version-1.693.html#improved-email-forwarders-loop-handling-in-the-exim-configuration)

Exim mail server configuration is updated to better handle loops in email forwarding rules.

Prior to this change, sending an email to an address that ends up creating a forwarding loop would always trigger a bounce (mail delivery error) to be returned to the sender. An error would be returned to the sender even if the original email message was successfully delivered.

The updated configuration will ignore forwarder loops and will deliver to all the remaining email addresses. In addition to gracefully discarding forwarder loops, the configuration is slightly simplified to use fewer Exim router clauses.

An example configuration that used to cause problems:

*   Normal mailbox `user1@example.com`.
*   Normal mailbox `user2@example.com`.
*   Forwarder rule from `user1@example.com` to `user2@example.com`.
*   Forwarder rule from `user2@example.com` to `user1@example.com`.

This configuration makes sure that any email sent to either `user1@example.com` or `user2@example.com` will be delivered to both mailboxes. This configuration used to cause surplus bounce messages to be sent back despite messages being successfully delivered to both mailboxes.

## Default MySQL/MariaDB UNIX socket path is /run/mysql/mysql.sock update[​](https://docs.directadmin.com/changelog/version-1.693.html#default-mysql-mariadb-unix-socket-path-is-run-mysql-mysql-sock)

The MySQL and MariaDB server configuration is updated to make sure the UNIX socket for accepting client connections will be created in `/run/mysql/mysql.sock`. Before this change, the default socket location used to be `/var/lib/mysql/mysql.sock`.

The old socket location was not ideal because it was placed in the same directory as the database data. Separating database data and connection socket locations allows us to have more strict access controls. For example, the `/run/mysql` directory can be exposed in the jailed environments without exposing database data files.

A symlink will be created in the old socket path pointing to the new location to make sure all existing clients can connect without any changes.

Note:

The new socket location will be used after MariaDB or MySQL is installed using CustomBuild. If CustomBuild detects an old configuration, it will start showing an update to reinstall the same MariaDB or MySQL version. The reinstall will make sure a new default socket path is used.

## Extended letsencrypt.sh script update[​](https://docs.directadmin.com/changelog/version-1.693.html#extended-letsencrypt-sh-script)

The script `letsencrypt.sh` (responsible for issuing ACME certificates) is updated to have a new internal sub-command. This sub-command is used when certificates are issued from the main DirectAdmin service.

This change allows us to change how the DirectAdmin main service uses this script while still keeping old script arguments working the same for compatibility reasons.

If this file is customised, please make sure to update it.

## Inconsistent or faulty checkbox styling evolution fix[​](https://docs.directadmin.com/changelog/version-1.693.html#inconsistent-or-faulty-checkbox-styling)

Some pages had inconsistent checkbox styling and issues with how they appear on mobile, which have now been fixed.

## Web server template token `NGINX_MOD_SECURITY_ENABLE` is removed removal[​](https://docs.directadmin.com/changelog/version-1.693.html#web-server-template-token-nginx-mod-security-enable-is-removed)

The token `NGINX_MOD_SECURITY_ENABLE` is no longer used in the Nginx web server templates. It used to be set to an include statement that includes ModSecurity-related Nginx configuration file.

This token will always be set to an empty value. If custom Nginx web server templates are being used, please make sure this token is not used.

## CustomBuild no longer supports installing MySQL 5.7 and MariaDB 10.3 removal[​](https://docs.directadmin.com/changelog/version-1.693.html#custombuild-no-longer-supports-installing-mysql-5-7-and-mariadb-10-3)

CustomBuild will not allow selecting the MySQL 5.7 or MariaDB 10.3 release as the preferred database server version.

*   The MySQL 5.7 official extended support ended in [October 2023](https://endoflife.date/mysql).
*   MariaDB 10.3 enterprise support ended in [May 2023](https://endoflife.date/mariadb).

Administrators will be notified with a message in the DirectAdmin messaging system if these software versions are detected on the system.

The support for this software is only removed from CustomBuild (a tool to install or reinstall additional software on the server). DirectAdmin can still continue to manage MySQL 5.7 and MariaDB 10.3 servers.

## Removed `use_syslogd` configuration option from `directadmin.conf`removal[​](https://docs.directadmin.com/changelog/version-1.693.html#removed-use-syslogd-configuration-option-from-directadmin-conf)

This configuration option can only be passed via the CLI arguments for the main DirectAdmin service or for the taskq executor. For example:

*   `da server --syslog`
*   `da taskq --syslog --run ...`

Logging to syslog is always enabled when the DirectAdmin service is started using systemd. There is no need to keep this option in the `directadmin.conf` file.

## Removed `rotate_httpd_error_log_global` configuration options from `directadmin.conf`removal[​](https://docs.directadmin.com/changelog/version-1.693.html#removed-rotate-httpd-error-log-global-configuration-options-from-directadmin-conf)

Error log truncation will work only on per-domain error log files. The global error log will not be automatically truncated by the DirectAdmin service. It is being managed by the logrotate rules.

## Removed `service_memory_usage.sh` script removal[​](https://docs.directadmin.com/changelog/version-1.693.html#removed-service-memory-usage-sh-script)

This script is no longer used by the "system services" page to retrieve system memory usage.
