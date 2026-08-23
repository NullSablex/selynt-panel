Title: Version 1.699 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.699.html

Markdown Content:
Released: 2026-04-14

*   [Service Log Viewer evolution new](https://docs.directadmin.com/changelog/version-1.699.html#service-log-viewer)
*   [Save File Manager editor options evolution new](https://docs.directadmin.com/changelog/version-1.699.html#save-file-manager-editor-options)
*   [Added cursor position to File Manager editor footer evolution new](https://docs.directadmin.com/changelog/version-1.699.html#added-cursor-position-to-file-manager-editor-footer)
*   [View User > User Domains evolution new](https://docs.directadmin.com/changelog/version-1.699.html#view-user-user-domains)
*   [TLS support for connecting to MySQL/MariaDB databases new](https://docs.directadmin.com/changelog/version-1.699.html#tls-support-for-connecting-to-mysql-mariadb-databases)
*   [Php-fpm support for OpenLiteSpeed custombuild new](https://docs.directadmin.com/changelog/version-1.699.html#php-fpm-support-for-openlitespeed)
*   [User Messages evolution update](https://docs.directadmin.com/changelog/version-1.699.html#user-messages)
*   [Simplified system file editor evolution update](https://docs.directadmin.com/changelog/version-1.699.html#simplified-system-file-editor)
*   [User Statistics evolution update](https://docs.directadmin.com/changelog/version-1.699.html#user-statistics)
*   [Disk Usage evolution update](https://docs.directadmin.com/changelog/version-1.699.html#disk-usage)
*   [Bandwidth & History Tables evolution update](https://docs.directadmin.com/changelog/version-1.699.html#bandwidth-history-tables)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.699.html#software-version-changes)
*   [Stats Search evolution fix](https://docs.directadmin.com/changelog/version-1.699.html#stats-search)
*   [Removed "Edit in new tab" action in File Manager evolution removal](https://docs.directadmin.com/changelog/version-1.699.html#removed-edit-in-new-tab-action-in-file-manager)
*   [Protected directories outside the document root directory removal](https://docs.directadmin.com/changelog/version-1.699.html#protected-directories-outside-the-document-root-directory)

## Service Log Viewer evolution new[​](https://docs.directadmin.com/changelog/version-1.699.html#service-log-viewer)

A dedicated log viewer has been added to each system service page. Users can now view service logs directly in the Evolution interface, with support for filtering by log level and date range.

![Image 1: Service Log Viewer](https://docs.directadmin.com/assets/service-log.BJjkhdGl.png)

## Save File Manager editor options evolution new[​](https://docs.directadmin.com/changelog/version-1.699.html#save-file-manager-editor-options)

File Manager now saves your editor preferences, including line numbers, line wrap, and tab size. Your selected options stay in place and no longer reset when the browser is reloaded.

The File Manager editor footer now displays the cursor position, including the current line and column.

## View User > User Domains evolution new[​](https://docs.directadmin.com/changelog/version-1.699.html#view-user-user-domains)

The View User page has been split into two separate pages: User Info and User Domains. This would simplify the layout of each page, provide better concern separation and improve navigating user-related resources.

## TLS support for connecting to MySQL/MariaDB databases new[​](https://docs.directadmin.com/changelog/version-1.699.html#tls-support-for-connecting-to-mysql-mariadb-databases)

The directadmin service settings for connecting to a remote MySQL/MariaDB server are updated to support enabling connection encryption.

The configuration file `/usr/local/directadmin/conf/mysql.conf` has two new fields:

*   `tls=yes/no` enables or disables encryption of the outgoing connections to the database server.
*   `tls_verify=yes/no` enables or disables strict verification of the server TLS certificate. Disabling the verification can be useful if the database server is using self-signed certificates.

![Image 2: Databse service settings](https://docs.directadmin.com/assets/db-settings-tls.BT_ffwD3.png)

## Php-fpm support for OpenLiteSpeed custombuild new[​](https://docs.directadmin.com/changelog/version-1.699.html#php-fpm-support-for-openlitespeed)

Removed the roadblock for using PHP-FPM with OpenLiteSpeed.

Slight template adjustments were made along the way:

*   added new `custombuild/configure/openlitespeed/httpd-webapps-fpm-extprocessor.template`
*   renamed old `custombuild/configure/openlitespeed/httpd-webapps-extprocessor.template` to `httpd-webapps-ls-extprocessor.template`
*   adjusted `data/templates/openlitespeed_vhost.conf`

## User Messages evolution update[​](https://docs.directadmin.com/changelog/version-1.699.html#user-messages)

The Messages page has been redesigned with a cleaner layout. A search field was added for filtering messages, the per-page selector was replaced with proper pagination.

![Image 3: Messages page after](https://docs.directadmin.com/assets/messages-after.C6d_IBVZ.png)

## Simplified system file editor evolution update[​](https://docs.directadmin.com/changelog/version-1.699.html#simplified-system-file-editor)

The previous system file editor included advanced features and extra options that were not needed for everyday tasks. In this release, it was replaced with a simpler standard editor to make file editing easier and more straightforward.

## User Statistics evolution update[​](https://docs.directadmin.com/changelog/version-1.699.html#user-statistics)

User stats have been restructured to be consistent with the reseller and server stats pages. AWStats setting has been moved from User Stats to the Domain Statistics page.

## Disk Usage evolution update[​](https://docs.directadmin.com/changelog/version-1.699.html#disk-usage)

Disk usage pages have been restyled, replacing the tabbed layout with a streamlined single-page experience.

## Bandwidth & History Tables evolution update[​](https://docs.directadmin.com/changelog/version-1.699.html#bandwidth-history-tables)

History and bandwidth breakdown tables have been updated with consistent table styling, and the chart/table toggle has been refreshed.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.699.html#software-version-changes)

*   **litespeed** updated from `6.3.5-0` to `6.3.5-1`
*   **ls-php-litespeed** updated from `8.1` to `8.3`
*   **nginx** updated from `1.29.7` to `1.29.8`
*   **phalcon** (PHP extension) updated from `5.10.0` to `5.11.1`
*   **PHP 8.4** updated from `8.4.19` to `8.4.20`
*   **PHP 8.5** updated from `8.5.4` to `8.5.5`
*   **ssh2** (PHP extension) updated from `1.4.1` to `1.5.0`

## Stats Search evolution fix[​](https://docs.directadmin.com/changelog/version-1.699.html#stats-search)

Stats pages are now correctly indexed for search, including bandwidth breakdown which previously was unsearchable.

## Removed "Edit in new tab" action in File Manager evolution removal[​](https://docs.directadmin.com/changelog/version-1.699.html#removed-edit-in-new-tab-action-in-file-manager)

The separate "Edit in new tab" action has been removed from File Manager. As the editor workflow has improved, this extra action is no longer needed.

## Protected directories outside the document root directory removal[​](https://docs.directadmin.com/changelog/version-1.699.html#protected-directories-outside-the-document-root-directory)

It will no longer be possible to password-protect directories that are outside of the virtual host document root directory.

Protecting such directories used to work only when the Apache web server was used. This change unifies how the protected directories work across all web servers.
