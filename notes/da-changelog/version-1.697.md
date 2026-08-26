Title: Version 1.697 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.697.html

Markdown Content:
Released: 2026-03-16

*   [Updated file editor in File Manager evolution update](https://docs.directadmin.com/changelog/version-1.697.html#updated-file-editor-in-file-manager)
*   [Default Move to trash option evolution update](https://docs.directadmin.com/changelog/version-1.697.html#default-move-to-trash-option)
*   [Improved page structures for users & resellers view evolution update](https://docs.directadmin.com/changelog/version-1.697.html#improved-page-structures-for-users-resellers-view)
*   [Old messages and tickets are cleaned up by default update](https://docs.directadmin.com/changelog/version-1.697.html#old-messages-and-tickets-are-cleaned-up-by-default)
*   [Refactored connection_info.sh script update](https://docs.directadmin.com/changelog/version-1.697.html#refactored-connection-info-sh-script)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.697.html#software-version-changes)
*   [Workaround for long database names that causes GRANT statements to fail fix](https://docs.directadmin.com/changelog/version-1.697.html#workaround-for-long-database-names-that-causes-grant-statements-to-fail)
*   [Do not reset Exim email blocking configuration on Exim rebuild custombuild fix](https://docs.directadmin.com/changelog/version-1.697.html#do-not-reset-exim-email-blocking-configuration-on-exim-rebuild)
*   [ModSecurity quick-exclude validation evolution fix](https://docs.directadmin.com/changelog/version-1.697.html#modsecurity-quick-exclude-validation)
*   [Removed API related environment variables from Plugin Manager removal](https://docs.directadmin.com/changelog/version-1.697.html#removed-api-related-environment-variables-from-plugin-manager)
*   [Removed user-level entries from reseller/admin menus evolution removal](https://docs.directadmin.com/changelog/version-1.697.html#removed-user-level-entries-from-reseller-admin-menus)
*   [Removed auto-patch option from the Administrator settings page evolution removal](https://docs.directadmin.com/changelog/version-1.697.html#removed-auto-patch-option-from-the-administrator-settings-page)

## Updated file editor in File Manager evolution update[​](https://docs.directadmin.com/changelog/version-1.697.html#updated-file-editor-in-file-manager)

The File Manager code editor was updated to a new built-in version. For most users, it works the same as before and keeps mostly the same editing experience.

The `.ini` and `.perl` files no longer have syntax highlighting. Also, the editor theme selector was removed, and the editor now switches automatically between light and dark modes based on your skin customization settings.

## Default `Move to trash` option evolution update[​](https://docs.directadmin.com/changelog/version-1.697.html#default-move-to-trash-option)

You can now choose whether `Move to trash` is enabled by default in the File Manager remove dialog.

This setting is available in _Skin Options > File Manager > Enable "Move to trash" by default_.

## Improved page structures for users & resellers view evolution update[​](https://docs.directadmin.com/changelog/version-1.697.html#improved-page-structures-for-users-resellers-view)

"Modify user"/"Modify reseller" were hidden inside tab panels of "View user"/"View reseller" pages. This led to confusing UI.

As part of ongoing work on improving user overview/modify, "Modify user"/"Modify reseller" pages were extracted into separate pages.

## Old messages and tickets are cleaned up by default update[​](https://docs.directadmin.com/changelog/version-1.697.html#old-messages-and-tickets-are-cleaned-up-by-default)

The default value for the configuration option `delete_messages_days` is changed from **0** (disabled) to **365** (1 year).

The default value for the configuration option `delete_tickets_days` is changed from **0** (disabled) to **730** (2 years).

These changes make sure old messages and tickets are automatically removed from the system.

## Refactored `connection_info.sh` script update[​](https://docs.directadmin.com/changelog/version-1.697.html#refactored-connection-info-sh-script)

The script `connection_info.sh` is used to collect information about connections to the server. It is executed when the server is under high load. The output of this script is sent to the server administrator.

Main changes:

*   Correctly handle IPv6 addresses. Old version used to truncate parts of IPv6 addresses together with the service port.
*   Extract connection info in a more efficient way.
*   Add socket usage statistics at the end of script output.
*   No longer execute the `connection_info_post.sh` hook.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.697.html#software-version-changes)

*   **igbinary** (PHP extension) updated from `3.2.16` to `3.2.17RC1`
*   **ioncube** (PHP extension) updated from `15.0.0` to `15.5.0`
*   **mod_lsapi** updated from `1.1-87` to `1.1-91`
*   **ModSecurity** rules from **OWASP CRS** updated from `4.24.0` to `4.24.1`
*   **nginx** updated from `1.29.5` to `1.29.6`
*   **PHP 8.4** updated from `8.4.18` to `8.4.19`
*   **PHP 8.5** updated from `8.5.3` to `8.5.4`

## Workaround for long database names that causes GRANT statements to fail fix[​](https://docs.directadmin.com/changelog/version-1.697.html#workaround-for-long-database-names-that-causes-grant-statements-to-fail)

The MySQL and MariaDB engines support database names up to 64 characters. The database management interface allows users to create databases with names up to this limit.

However, the real limit might be shorter depending on how many `_` symbols are in the database name.

The problem is reported upstream in [MDEV-39047](https://jira.mariadb.org/browse/MDEV-39047).

A workaround is added to reject database names that can cause problems with GRANT statements.

## Do not reset Exim email blocking configuration on Exim rebuild custombuild fix[​](https://docs.directadmin.com/changelog/version-1.697.html#do-not-reset-exim-email-blocking-configuration-on-exim-rebuild)

The file `/etc/virtual/use_rbl_domains` can be used to control if Exim should perform spam blocking rules. This file used to be reset to enable it for all domains every time Exim is recompiled.

The issue is fixed, and this file will only be updated during the initial DirectAdmin installation.

## ModSecurity quick-exclude validation evolution fix[​](https://docs.directadmin.com/changelog/version-1.697.html#modsecurity-quick-exclude-validation)

When excluding a rule from the ModSecurity configuration via the audit page, an error could be triggered if the rule message was too long or contained control characters.

Additional validation was introduced to sanitize rule messages before the quick-exclude action.

Plugin scripts executed by Plugin Manager (`install.sh`, `uninstall.sh`, `update.sh`) no longer have access to environment variables related to the API request that triggered their execution.

## Removed user-level entries from reseller/admin menus evolution removal[​](https://docs.directadmin.com/changelog/version-1.697.html#removed-user-level-entries-from-reseller-admin-menus)

"SSH Keys" menu entry was used in the reseller-level menu; "Help" menu entry was used in both admin and reseller-level menus. These entries have been removed to separate areas of responsibility, improve menu consistency, and eliminate the possibility of undefined behavior in menu customization.

## Removed auto-patch option from the Administrator settings page evolution removal[​](https://docs.directadmin.com/changelog/version-1.697.html#removed-auto-patch-option-from-the-administrator-settings-page)

The option to enable or disable automatic hotfix releases for DirectAdmin is removed from the user interface. This option can still be managed using CLI commands `da config-set autopatch 1` and `da config-set autopatch 0`.

Disabling automatic hotfix release installation is strongly discouraged.
