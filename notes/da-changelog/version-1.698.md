Title: Version 1.698 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.698.html

Markdown Content:
Released: 2026-03-31

*   [Message Templates evolution new](https://docs.directadmin.com/changelog/version-1.698.html#message-templates)
*   [Domain Statistics Page evolution new](https://docs.directadmin.com/changelog/version-1.698.html#domain-statistics-page)
*   [Improved OpenLiteSpeed protected directories template update](https://docs.directadmin.com/changelog/version-1.698.html#improved-openlitespeed-protected-directories-template)
*   [Default value for numservers_waiting option update](https://docs.directadmin.com/changelog/version-1.698.html#default-value-for-numservers-waiting-option)
*   [Plugin manager delete action error handling update](https://docs.directadmin.com/changelog/version-1.698.html#plugin-manager-delete-action-error-handling)
*   [Cleanup when disabling directory password protection update](https://docs.directadmin.com/changelog/version-1.698.html#cleanup-when-disabling-directory-password-protection)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.698.html#software-version-changes)
*   [Upgraded system file editor evolution update](https://docs.directadmin.com/changelog/version-1.698.html#upgraded-system-file-editor)
*   [TAB indentation in File Manager editor evolution update](https://docs.directadmin.com/changelog/version-1.698.html#tab-indentation-in-file-manager-editor)
*   [Navigation Error Handling evolution update](https://docs.directadmin.com/changelog/version-1.698.html#navigation-error-handling)
*   [404 Page evolution update](https://docs.directadmin.com/changelog/version-1.698.html#_404-page)
*   [Server Stats evolution update](https://docs.directadmin.com/changelog/version-1.698.html#server-stats)
*   [ModSecurity Logs evolution update](https://docs.directadmin.com/changelog/version-1.698.html#modsecurity-logs)
*   [System service list is empty if there are masked services fix](https://docs.directadmin.com/changelog/version-1.698.html#system-service-list-is-empty-if-there-are-masked-services)
*   [View User History evolution fix](https://docs.directadmin.com/changelog/version-1.698.html#view-user-history)

## Message Templates evolution new[​](https://docs.directadmin.com/changelog/version-1.698.html#message-templates)

Suspension message and welcome message are now consolidated under a single "Message Templates" menu entry, reducing clutter in the navigation.

## Domain Statistics Page evolution new[​](https://docs.directadmin.com/changelog/version-1.698.html#domain-statistics-page)

Domain statistics have been extracted from the User statistics page into a dedicated page. This separates concerns that were previously mixed together — domain stats / logs and user statistics/info.

## Improved OpenLiteSpeed protected directories template update[​](https://docs.directadmin.com/changelog/version-1.698.html#improved-openlitespeed-protected-directories-template)

The template that controls how password-protected directories are configured for the OpenLiteSpeed web server is updated. The old template file `openlitespeed_context_protected.conf` allowed to configure only the `context` section of the configuration. The `realm` section was hard-coded in the main DirectAdmin service.

The old template is replaced with the new template file `openlitespeed_protected_directory.conf`. The new file configures both `context` and `realm` sections. This allows full control of the password-protected directory configuration.

The main OpenLiteSpeed virtual host configuration template `openlitespeed_vhost.conf` have access to the two new tokens:

*   `|PROTECTED_DIRECTORIES|` contains the configuration blob for all protected directories in this virtual host.
*   `|CGI_BIN_DIRECTORY|` contains the configuration blob for the `cgi-bin` directory if the user has `cgi-bin` support enabled.

These new tokens replace the legacy `|CONTEXTS|` and `|REALMS|` tokens.

‼️ If the `openlitespeed_vhost.conf` template is customised, please update it accordingly. Replace the `|CONTEXTS|` with `|CGI_BIN_DIRECTORY|` token and the `|REALMS|` with `|PROTECTED_DIRECTORIES|` token.

For compatibility reasons the old tokens will still be available and contain the same configuration as the new tokens.

## Default value for `numservers_waiting` option update[​](https://docs.directadmin.com/changelog/version-1.698.html#default-value-for-numservers-waiting-option)

The default value for the `numservers_waiting` option is changed from 10 processes to 2 processes.

This option controls how many idle `directadmin` processes should be waiting for new connections. As soon as an idle process starts processing a request, a new idle process is started. Lowering this value does not limit how many concurrent requests can be processed.

## Plugin manager delete action error handling update[​](https://docs.directadmin.com/changelog/version-1.698.html#plugin-manager-delete-action-error-handling)

The following changes were made to `CMD_PLUGIN_MANAGER` delete action:

*   plugin is no longer removed if plugin's `uninstall.sh` script fails.
*   no longer returns error if `uninstall.sh` script is missing.

## Cleanup when disabling directory password protection update[​](https://docs.directadmin.com/changelog/version-1.698.html#cleanup-when-disabling-directory-password-protection)

When password protection from the directory is removed, all the protection-related configuration from the `.htaccess` file and the whole `.htpasswd` file will be removed.

This change makes sure that removing password protection restores the directory to the same state it was before protecting it and does not leave any stray files behind.

This change affects only the Enhanced skin and legacy API endpoint. The Evolution skin was always performing a full cleanup. Now both skins will start behaving the same.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.698.html#software-version-changes)

*   **dovecot** updated from `2.4.2` to `2.4.3`
*   **litespeed** updated from `6.3.4-11` to `6.3.5-0`
*   **ModSecurity** rules from **OWASP CRS** updated from `4.24.1` to `4.25.0`
*   **nginx** updated from `1.29.6` to `1.29.7`
*   **redis** updated from `8.6.0` to `8.6.2`
*   **roundcubemail** updated from `1.6.13` to `1.6.15`
*   **xapian-core** updated from `1.4.31` to `2.0.0`

## Upgraded system file editor evolution update[​](https://docs.directadmin.com/changelog/version-1.698.html#upgraded-system-file-editor)

The system file editor was upgraded and now matches the File Manager editor, including the same design and core functionality.

A filter was added to the system file list, making it easier to find a specific file quickly.

## TAB indentation in File Manager editor evolution update[​](https://docs.directadmin.com/changelog/version-1.698.html#tab-indentation-in-file-manager-editor)

The File Manager editor now supports TAB indentation.

The option in the file editor's footer allows user to change the tab size between 2 or 4 spaces. By default it is set to 4.

To move focus out of the editor, press the Escape key.

## Navigation Error Handling evolution update[​](https://docs.directadmin.com/changelog/version-1.698.html#navigation-error-handling)

Unauthorized and disabled pages now resolve to a 404 instead of rejecting navigation outright. This aligns error handling with the principle of always completing navigation, even when the destination is unavailable.

## 404 Page evolution update[​](https://docs.directadmin.com/changelog/version-1.698.html#_404-page)

The 404 page has been restyled with branding colors for visual consistency. Error codes are now included to distinguish between not-found, forbidden, and disabled states.

## Server Stats evolution update[​](https://docs.directadmin.com/changelog/version-1.698.html#server-stats)

Reseller and server stats have been refactored to use nested routes, with admin and reseller history moved inside their respective stats sections. Filesystems and network device stats sections have been removed.

## ModSecurity Logs evolution update[​](https://docs.directadmin.com/changelog/version-1.698.html#modsecurity-logs)

Logs can now be reloaded without a full page refresh.

## System service list is empty if there are masked services fix[​](https://docs.directadmin.com/changelog/version-1.698.html#system-service-list-is-empty-if-there-are-masked-services)

If one of the system services is masked (explicitly disabled by the system administrator), the list of system services would show an error. The service management interface is updated to hide masked services.

## View User History evolution fix[​](https://docs.directadmin.com/changelog/version-1.698.html#view-user-history)

When a reseller viewed a user's history, the request was missing the user parameter, causing it to always fetch the reseller's own history instead. The correct user is now passed through.
