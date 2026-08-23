Title: Version 1.700 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.700.html

Markdown Content:
Released: 2026-04-28

*   [Disk usage statistics for legacy DirectAdmin codebase update](https://docs.directadmin.com/changelog/version-1.700.html#disk-usage-statistics-for-legacy-directadmin-codebase)
*   [Isolated PHP-FPM mode for legacy DirectAdmin codebase update](https://docs.directadmin.com/changelog/version-1.700.html#isolated-php-fpm-mode-for-legacy-directadmin-codebase)
*   [Simplified Easy Spam Fighter install and uninstall commands custombuild update](https://docs.directadmin.com/changelog/version-1.700.html#simplified-easy-spam-fighter-install-and-uninstall-commands)
*   [Rspamd integration is now part of Exim configuration custombuild update](https://docs.directadmin.com/changelog/version-1.700.html#rspamd-integration-is-now-part-of-exim-configuration)
*   [Plugin Manager redesign evolution update](https://docs.directadmin.com/changelog/version-1.700.html#plugin-manager-redesign)
*   [Unify DNS record creation and edit evolution update](https://docs.directadmin.com/changelog/version-1.700.html#unify-dns-record-creation-and-edit)
*   [File Manager editor shown as full page evolution update](https://docs.directadmin.com/changelog/version-1.700.html#file-manager-editor-shown-as-full-page)
*   [Improved File Manager file selection behavior evolution update](https://docs.directadmin.com/changelog/version-1.700.html#improved-file-manager-file-selection-behavior)
*   [Open files and folders in a new tab from File Manager evolution update](https://docs.directadmin.com/changelog/version-1.700.html#open-files-and-folders-in-a-new-tab-from-file-manager)
*   [Toggle Buttons evolution update](https://docs.directadmin.com/changelog/version-1.700.html#toggle-buttons)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.700.html#software-version-changes)
*   [Return TTL value for NS records fix](https://docs.directadmin.com/changelog/version-1.700.html#return-ttl-value-for-ns-records)
*   [Add validation for MX DNS record inputs evolution fix](https://docs.directadmin.com/changelog/version-1.700.html#add-validation-for-mx-dns-record-inputs)
*   [Use pointer domain for DNS record hints evolution fix](https://docs.directadmin.com/changelog/version-1.700.html#use-pointer-domain-for-dns-record-hints)
*   [Invisible charts in Resource Limits evolution fix](https://docs.directadmin.com/changelog/version-1.700.html#invisible-charts-in-resource-limits)
*   [Overlapping tables on Git page evolution fix](https://docs.directadmin.com/changelog/version-1.700.html#overlapping-tables-on-git-page)
*   [Domain Search evolution fix](https://docs.directadmin.com/changelog/version-1.700.html#domain-search)
*   [Removed "Copy" from DNS records evolution removal](https://docs.directadmin.com/changelog/version-1.700.html#removed-copy-from-dns-records)
*   [Removed email size threshold for spam checking in Easy Spam Fighter custombuild removal](https://docs.directadmin.com/changelog/version-1.700.html#removed-email-size-threshold-for-spam-checking-in-easy-spam-fighter)
*   [Removed "System Information" menu entry from admin and reseller levels evolution removal](https://docs.directadmin.com/changelog/version-1.700.html#removed-system-information-menu-entry-from-admin-and-reseller-levels)
*   [Admin SSL: pointers with own cert not showing active/verified fix](https://docs.directadmin.com/changelog/version-1.700.html#admin-ssl-pointers-with-own-cert-not-showing-active-verified)

## Disk usage statistics for legacy DirectAdmin codebase update[​](https://docs.directadmin.com/changelog/version-1.700.html#disk-usage-statistics-for-legacy-directadmin-codebase)

Disk usage statistics are backported into the legacy DirectAdmin code base.

## Isolated PHP-FPM mode for legacy DirectAdmin codebase update[​](https://docs.directadmin.com/changelog/version-1.700.html#isolated-php-fpm-mode-for-legacy-directadmin-codebase)

Support for running fully isolated user owned PHP-FPM instances in backported to the legacy DirectAdmin code base.

## Simplified Easy Spam Fighter install and uninstall commands custombuild update[​](https://docs.directadmin.com/changelog/version-1.700.html#simplified-easy-spam-fighter-install-and-uninstall-commands)

The command to install Easy Spam Fighter `da build easy_spam_fighter` is now an alias to `da build exim_conf`.

The command to remove Easy Spam Fighter `da build remove_easy_spam_fighter` is removed. When ESF is disabled, it will be automatically removed with the next Exim configuration update.

The following commands should be used for toggling ESF on or off:

sh

```
# Enable ESF
da build set easy_spam_fighter yes
da build exim_conf

# Disable ESF
da build set easy_spam_fighter no
da build exim_conf
```

## Rspamd integration is now part of Exim configuration custombuild update[​](https://docs.directadmin.com/changelog/version-1.700.html#rspamd-integration-is-now-part-of-exim-configuration)

The CustomBuild command `da build rspamd_conf` is now an alias to the `da build exim_conf` command. When the Rspamd service is installed or removed, CustomBuild will automatically update the Exim configuration.

## Plugin Manager redesign evolution update[​](https://docs.directadmin.com/changelog/version-1.700.html#plugin-manager-redesign)

Plugin Manager page (reachable via admin level) has been redesigned with new API endpoints:

*   Install/Uninstall actions were obfuscated in favor of performing them as part of upload/delete process. It's still possible for a plugin to have `installed=no` state, but in those cases a warning will be shown.
*   Table design was dropped in favor of card based design. This reduces visual noise by hiding unavailable data completely instead of showing placeholders.
*   Plugin upload dialog was moved inside the page directly.

![Image 1: New Plugin Manager](https://docs.directadmin.com/assets/plugin-manager.CIHRymOt.png)

## Unify DNS record creation and edit evolution update[​](https://docs.directadmin.com/changelog/version-1.700.html#unify-dns-record-creation-and-edit)

DNS record creation and edit dialogs now opt in to manual editing for TXT records the same way - by selecting "Plain" using "TXT Record Type" input field.

Subsequently, the "Edit Manually" checkbox for SRV records was moved directly below "TTL" input field.

## File Manager editor shown as full page evolution update[​](https://docs.directadmin.com/changelog/version-1.700.html#file-manager-editor-shown-as-full-page)

The File Manager editor is now displayed as a full page. The sidebar is hidden, and other interface elements were improved to provide a better file editing experience.

## Improved File Manager file selection behavior evolution update[​](https://docs.directadmin.com/changelog/version-1.700.html#improved-file-manager-file-selection-behavior)

File selection behavior in File Manager was improved to make selecting files and folders more predictable and easier to use.

Main changes:

1.   Clicking a file row (not the checkbox) selects only that file and deselects the rest.
2.   Double-clicking opens the file or folder.
3.   Clicking a checkbox adds or removes that file without clearing the current selection.
4.   Shift + click selects a range from the last selected item.
5.   Ctrl or Cmd (for Mac users) + click adds or removes individual files and folders from the selection.
6.   Right-clicking an unselected item clears the current selection, selects that item, and opens its context menu.
7.   Right-clicking already selected items opens the context menu for that selection.
8.   Clicking empty space below the table clears the selection.

## Open files and folders in a new tab from File Manager evolution update[​](https://docs.directadmin.com/changelog/version-1.700.html#open-files-and-folders-in-a-new-tab-from-file-manager)

In version 1.699, we removed the `Edit in new tab` action because it was no longer needed as a separate option. The `Edit` and `Open` actions are now regular links, so you can use your browser's standard options to open them in a new tab, a new window, or elsewhere.

## Toggle Buttons evolution update[​](https://docs.directadmin.com/changelog/version-1.700.html#toggle-buttons)

Toggle button pattern has been standardized across the panel. Fixes dark mode contrast issues in several places that used the previous implementation.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.700.html#software-version-changes)

*   **composer** updated from `2.9.5` to `2.9.7`
*   **litespeed** updated from `6.3.5-1` to `6.3.5-2`
*   **mod_lsapi** updated from `1.1-91` to `1.1-92`
*   **MySQL 8.0** updated from `8.0.45` to `8.0.46`
*   **MySQL 8.4** updated from `8.4.8` to `8.4.9`
*   **nginx** updated from `1.29.8` to `1.30.0`
*   **ngx_cache_purge** updated from `2.5.6` to `3.0.1`
*   **openlitespeed** updated from `1.8.5` to `1.9.0`
*   **proftpd** updated from `1.3.9` to `1.3.9a`

## Return TTL value for NS records fix[​](https://docs.directadmin.com/changelog/version-1.700.html#return-ttl-value-for-ns-records)

Endpoints `CMD_DNS_CONTROL`, `CMD_DNS_ADMIN`, `CMD_DNS_RESELLER` now return TTL value for NS records.

## Add validation for MX DNS record inputs evolution fix[​](https://docs.directadmin.com/changelog/version-1.700.html#add-validation-for-mx-dns-record-inputs)

Inputs are now validated when creating or editing MX records

## Use pointer domain for DNS record hints evolution fix[​](https://docs.directadmin.com/changelog/version-1.700.html#use-pointer-domain-for-dns-record-hints)

When creating or editing a DNS record for domain pointer, value input field showed domain within hint when it should have showed pointer domain instead.

## Invisible charts in Resource Limits evolution fix[​](https://docs.directadmin.com/changelog/version-1.700.html#invisible-charts-in-resource-limits)

Circle charts on the Resource Limits page could appear invisible because of color issues. This release fixes the chart colors so usage data is visible again.

## Overlapping tables on Git page evolution fix[​](https://docs.directadmin.com/changelog/version-1.700.html#overlapping-tables-on-git-page)

Tables on the Git page could overlap each other. This release fixes the layout so all table content is displayed correctly.

## Domain Search evolution fix[​](https://docs.directadmin.com/changelog/version-1.700.html#domain-search)

Searching for a domain now correctly navigates to the domain edit page.

## Removed "Copy" from DNS records evolution removal[​](https://docs.directadmin.com/changelog/version-1.700.html#removed-copy-from-dns-records)

Dropped "Copy" table action from the following pages:

*   user level "MX Records"
*   user level "DNS Management"
*   reseller and admin level "DNS Administration"

## Removed email size threshold for spam checking in Easy Spam Fighter custombuild removal[​](https://docs.directadmin.com/changelog/version-1.700.html#removed-email-size-threshold-for-spam-checking-in-easy-spam-fighter)

The maximum size limit for email messages to be checked with a spam service (SpamAssassin or Rspamd) is removed. The Easy Spam Fighter configuration is updated to always perform a spam scan.

This limit used to be too small (default value was 200 KB) and was an easy way to bypass spam checking. Now each spam service is responsible for checking the message size and deciding if it needs to be fully or partially checked for spam. This allows spam checking of emails with a large file attached.

The message size limit used to be managed with the option `EASY_SPAMASSASSIN_MAX_SIZE` in the `/etc/exim.easy_spam_fighter/variables.conf` file. This variable is no longer used and removed from the default ESF configuration.

## Removed "System Information" menu entry from admin and reseller levels evolution removal[​](https://docs.directadmin.com/changelog/version-1.700.html#removed-system-information-menu-entry-from-admin-and-reseller-levels)

"System Information" page is now only available from the user level.

## Admin SSL: pointers with own cert not showing active/verified fix[​](https://docs.directadmin.com/changelog/version-1.700.html#admin-ssl-pointers-with-own-cert-not-showing-active-verified)

The `/evo/admin/ssl` page (aka: `CMD_ADMN_SSL?json=yes`) was incorrectly showing the state of domain pointer certificates for the `SSL` and `Active`columns.
