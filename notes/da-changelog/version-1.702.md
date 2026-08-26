Title: Version 1.702 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.702.html

Published Time: Thu, 28 May 2026 08:00:01 GMT

Markdown Content:
Released: 2026-05-18

*   [HSTS option in Domain Setup evolution new](https://docs.directadmin.com/changelog/version-1.702.html#hsts-option-in-domain-setup)
*   [Pending server restart notification new](https://docs.directadmin.com/changelog/version-1.702.html#pending-server-restart-notification)
*   [Updated URLs evolution update](https://docs.directadmin.com/changelog/version-1.702.html#updated-urls)
*   [Disable "Save" button when permission is denied evolution update](https://docs.directadmin.com/changelog/version-1.702.html#disable-save-button-when-permission-is-denied)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.702.html#software-version-changes)
*   [Sent email limits will count local-to-local emails update](https://docs.directadmin.com/changelog/version-1.702.html#sent-email-limits-will-count-local-to-local-emails)
*   [A link to switch from Enhanced to Evolution skin update](https://docs.directadmin.com/changelog/version-1.702.html#a-link-to-switch-from-enhanced-to-evolution-skin)
*   [Direct spam-checking service integration into Exim update](https://docs.directadmin.com/changelog/version-1.702.html#direct-spam-checking-service-integration-into-exim)
*   [Roundcube installation improvements update](https://docs.directadmin.com/changelog/version-1.702.html#roundcube-installation-improvements)
*   [Show details in backup status dialog evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#show-details-in-backup-status-dialog)
*   [Get rid of empty space within reseller backups page evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#get-rid-of-empty-space-within-reseller-backups-page)
*   [Fix missing table pagination on some pages evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#fix-missing-table-pagination-on-some-pages)
*   [Hide File Manager editor links when access is denied evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#hide-file-manager-editor-links-when-access-is-denied)
*   [Fix missing data in server usage statistics evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#fix-missing-data-in-server-usage-statistics)
*   [Remove domain selector from subdomain logs page evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#remove-domain-selector-from-subdomain-logs-page)
*   [Improve protected directories validation evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#improve-protected-directories-validation)
*   [Limit database name length to less than 64 characters evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#limit-database-name-length-to-less-than-64-characters)
*   [Fix "View more" widget link evolution fix](https://docs.directadmin.com/changelog/version-1.702.html#fix-view-more-widget-link)
*   [Password-protected directory configuration for Nginx fix](https://docs.directadmin.com/changelog/version-1.702.html#password-protected-directory-configuration-for-nginx)
*   [cpanel restore: LetsEncrypt/ZeroSSL: ensure domain.com.cert.creation_time fix](https://docs.directadmin.com/changelog/version-1.702.html#cpanel-restore-letsencrypt-zerossl-ensure-domain-com-cert-creation-time)
*   [Race condition: users.list, reseller.list, admin.list fix](https://docs.directadmin.com/changelog/version-1.702.html#race-condition-users-list-reseller-list-admin-list)
*   [Cache available plugin version fix](https://docs.directadmin.com/changelog/version-1.702.html#cache-available-plugin-version)
*   [Remove unused "Notify" checkbox from vacation message form evolution removal](https://docs.directadmin.com/changelog/version-1.702.html#remove-unused-notify-checkbox-from-vacation-message-form)
*   [Removed plugin installed state from Plugin Manager removal](https://docs.directadmin.com/changelog/version-1.702.html#removed-plugin-installed-state-from-plugin-manager)

## HSTS option in Domain Setup evolution new[​](https://docs.directadmin.com/changelog/version-1.702.html#hsts-option-in-domain-setup)

Evolution now supports enabling HSTS (HTTP Strict Transport Security) per domain, matching the functionality already available in the Enhanced skin. You can enable this option when editing a domain.

You can also enable HSTS for subdomains and choose the `max-age` value for the HSTS header.

Only enable HSTS after SSL certificates are working for all related hosts. If HSTS is enabled without valid SSL, users may not be able to access the site.

![Image 1: Domain HSTS configuration](https://docs.directadmin.com/assets/domain-hsts-config.C7ZAxO3H.png)

## Pending server restart notification new[​](https://docs.directadmin.com/changelog/version-1.702.html#pending-server-restart-notification)

A new integration with the `needrestart` tool is added. If this tool is installed, it will be used to detect a situation when a new Linux kernel package has been installed but the server was not rebooted and is still using the old kernel.

A system message will be sent to all server administrators with a reminder to restart the server.

Installation of this tool is managed by CustomBuild. A new configuration option `needrestart=yes/no` is introduced in the CustomBuild options.conf file. This option is enabled by default. CustomBuild will show an available update if this tool is not installed on the server.

If pending server restart notifications are not needed, it can be disabled with this command:

`da build set needrestart no`

## Updated URLs evolution update[​](https://docs.directadmin.com/changelog/version-1.702.html#updated-urls)

Role based prefixes (`user/`, `reseller/`, `admin/`) have been removed from all URLs. Pages can still be accessed with old URLs, but this may be removed in a future release.

## Disable "Save" button when permission is denied evolution update[​](https://docs.directadmin.com/changelog/version-1.702.html#disable-save-button-when-permission-is-denied)

Previously, the File Manager editor still allowed users to click "Save" even when they did not have the `filemanager-actions` permission, and only then showed a soft error.

Now, the "Save" button is disabled for users who do not have this permission.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.702.html#software-version-changes)

*   **composer** updated from `2.9.7` to `2.9.8`
*   **dovecot** updated from `2.4.3` to `2.4.4`
*   **exim** updated from `4.99.2` to `4.99.3`
*   **litespeed** updated from `6.3.5-5` to `6.3.5-6`
*   **MariaDB 10.11** updated from `10.11.16` to `10.11.17`
*   **MariaDB 10.6** updated from `10.6.25` to `10.6.26`
*   **MariaDB 11.4** updated from `11.4.10` to `11.4.11`
*   **MariaDB 11.8** updated from `11.8.6` to `11.8.7`
*   **nginx** updated from `1.30.1` to `1.31.1`
*   **ngx_cache_purge** updated from `3.0.1` to `3.0.2`
*   **openlitespeed** updated from `1.9.0` to `1.9.0.1`
*   **phalcon** (PHP extension) updated from `5.11.1` to `5.13.0`
*   **redis** updated from `8.6.2` to `8.6.3`
*   **roundcubemail** updated from `1.6.15` to `1.7.1`

## Sent email limits will count local-to-local emails update[​](https://docs.directadmin.com/changelog/version-1.702.html#sent-email-limits-will-count-local-to-local-emails)

The limits system for counting sent emails is restructured. Key improvements:

*   Sent email counting is moved from Exim router to the Exim ACL stage.
*   Emails over the sent limit will always be rejected before entering the Exim mail queue. It will no longer be possible for email to bounce from the router.
*   Emails sent from one mailbox to the other mailbox on the same server (local-to-local emails) will be properly accounted for.
*   Sent email counting is faster. Temporary files in the `/etc/virtual/usage/{name}_ids` directory are no longer needed.

* * *

Changes in configuration files:

| File | Action | Comment |
| --- | --- | --- |
| `.../configure/exim/exim.conf` | ⚠️ updated | Moved limits check from SMTP routers to the last stage of ACLs. |
| `.../configure/exim/exim.pl` | ⚠️ updated | Replaced sent email limits checking and updating logic. |
| `.../configure/exim/exim.strings.conf` | ⚠️ updated | Removed no longer used `USER_TOO_MANY` and `AUTH_TOO_MANY` messages, updated `USER_ON_BLACKLIST_SCRIPT` message. |

If any of the updated or removed files were customised, please adjust them to stay in sync with the new configuration layout.

## A link to switch from Enhanced to Evolution skin update[​](https://docs.directadmin.com/changelog/version-1.702.html#a-link-to-switch-from-enhanced-to-evolution-skin)

The Enhanced skin navigation bar is updated to have a link to switch to the Evolution skin.

Enhanced skin is no longer actively maintained. The easy way to temporarily switch skin will allow users to access features that are not available in Enhanced skin.

## Direct spam-checking service integration into Exim update[​](https://docs.directadmin.com/changelog/version-1.702.html#direct-spam-checking-service-integration-into-exim)

The Exim mail server configuration is updated to have direct integration with spam-checking services Rspamd or SpamAssassin.

In previous DirectAdmin versions there were three different ways of performing spam checking:

*   Exim and SpamAssassin without Easy Spam Fighter. It used outdated integration that uses custom Exim transport.
*   Exim and SpamAssassin with Easy Spam Fighter. This mode disables legacy integration. Easy Spam Fighter would use SpamAssassin for spam checking.
*   Exim and Rspamd with Easy Spam Fighter. In this mode, Easy Spam Fighter would use Rspamd for spam checking.

The new Exim configuration has direct integration with spam-checking services. Using Easy Spam Fighter is no longer mandatory. Key benefits of the new configuration structure:

*   When SpamAssassin is used **without** Easy Spam Fighter, the Exim server will use modern spam-checking integration. Same integration that would be used **with** Easy Spam Fighter. This means spam can be rejected with Exim ACLs while the SMTP session is still active. Instead of accepting the message and checking for spam later.
*   It is now possible to use Rspamd without Easy Spam Fighter.
*   It is now possible to use Easy Spam Fighter without a spam-checking service (`spamd=no` in CustomBuild `options.conf` file).

Notable configuration changes on the system:

*   Exim spam checking configuration will be stored in these files: 
    *   `/etc/exim/spamd.global.conf`
    *   `/etc/exim/spamd.acl_smtp_data.conf`

*   Spam configuration files are included in the main `/etc/exim.conf` file.
*   Old rspamd configuration files in `/etc/exim/rspamd` are removed.
*   The legacy integration configuration file `/etc/exim.spamassassin.conf` is removed.

* * *

Here is the list of how this change is reflected in the CustomBuild configuration files structure.

| File | Action | Comment |
| --- | --- | --- |
| `.../configure/exim/exim.spamassassin.conf` | ❌ removed | Legacy integration using Exim transport. Not supported anymore. |
| `.../configure/rspamd/check_message.conf` | ❌ removed | Spam checking logic, now stored in `exim/rspamd.acl_smtp_data.conf`. |
| `.../configure/rspamd/connect.conf` | ❌ removed | No longer relevant. |
| `.../configure/rspamd/variables.conf` | ❌ removed | Global configuration, now stored in `exim/rspamd.global.conf`. |
| `.../configure/easy_spam_fighter/check_rcpt.mid.conf` | ❌ removed | ACL variables `acl_m_spam_user` and `acl_m_spam_domain` are now set in the main `exim.conf`. |
| `.../configure/easy_spam_fighter/check_mail.conf` | ⚠️ updated | ACL variables `acl_m_spam_user` and `acl_m_spam_domain` are now set in the main `exim.conf`. |
| `.../configure/easy_spam_fighter/check_message.conf` | ⚠️ updated | It will no longer connect to spam-checking service. It expects Exim to perform it. |
| `.../configure/easy_spam_fighter/connect.conf` | ⚠️ updated | No longer has Rspamd-specific logic. |
| `.../configure/easy_spam_fighter/variables.conf` | ⚠️ updated | No longer has Rspamd-specific logic. |
| `.../configure/exim/exim.conf` | ⚠️ updated | Performs spam checking by including `/etc/exim/spamd.global.conf` and `/etc/exim/spamd.acl_smtp_data.conf`. |
| `.../configure/exim/rspamd.acl_smtp_data.conf` | ✅ new | Performs spam checking with Rspamd, the same logic used to be in `rspamd/check_message.conf`. |
| `.../configure/exim/rspamd.global.conf` | ✅ new | Global configuration for connection to Rspamd, the same logic used to be in `rspamd/variables.conf`. |
| `.../configure/exim/spamassassin.acl_smtp_data.conf` | ✅ new | Performs spam checking with SpamAssassin, the same logic used to be in `easy_spam_fighter/check_message.conf`. |
| `.../configure/exim/spamassassin.global.conf` | ✅ new | Global configuration for connection to SpamAssassin. |

If any of the updated or removed files were customised, please adjust them to stay in sync with the new configuration layout.

## Roundcube installation improvements update[​](https://docs.directadmin.com/changelog/version-1.702.html#roundcube-installation-improvements)

Roundcube 1.7 enforces a mandatory public_html entry point, which required changes to the CustomBuild installation procedure.

*   Roundcube is now installed to `/var/www/webapps/` with the `public_html` directory symlinked to `/var/www/html/roundcube`
*   Log directory is moved to `/var/log/roundcube` (previously `/var/www/html/roundcube/logs`)
*   Temporary files dir is moved to `/var/www/tmp/roundcube` (previously `/var/www/html/roundcube/temp`)

## Show details in backup status dialog evolution fix[​](https://docs.directadmin.com/changelog/version-1.702.html#show-details-in-backup-status-dialog)

The backup status dialog (located in **Admin Backup and Restore** ->**In Progress** ->**Details**) now displays `Details:` section.

## Get rid of empty space within reseller backups page evolution fix[​](https://docs.directadmin.com/changelog/version-1.702.html#get-rid-of-empty-space-within-reseller-backups-page)

The content of reseller backups page (located in **Reseller Tools** ->**Manage User Backups**) no longer appears at the bottom of the screen.

## Fix missing table pagination on some pages evolution fix[​](https://docs.directadmin.com/changelog/version-1.702.html#fix-missing-table-pagination-on-some-pages)

Some pages could lose table pagination when invalid values (0 or negative numbers) were passed to the "Rows per page" or "Page number" properties. Table pagination is now displayed correctly.

## Hide File Manager editor links when access is denied evolution fix[​](https://docs.directadmin.com/changelog/version-1.702.html#hide-file-manager-editor-links-when-access-is-denied)

Some Evolution actions redirected users to the File Manager editor for quick file changes. If a user did not have access to File Manager, those redirects still ran and caused errors.

To prevent this, the affected actions were removed or hidden on the Custom Error Pages and SpamAssassin page. These files can still be opened and edited through other available methods.

## Fix missing data in server usage statistics evolution fix[​](https://docs.directadmin.com/changelog/version-1.702.html#fix-missing-data-in-server-usage-statistics)

Some values in the server usage statistics table (`/evo/server-stats/usage`) could be missing when `admin.allocation` or `admin.usage` files are missing, unreadable, or malformed. Error handling has been improved, and available statistics now display correctly.

## Remove domain selector from subdomain logs page evolution fix[​](https://docs.directadmin.com/changelog/version-1.702.html#remove-domain-selector-from-subdomain-logs-page)

Selecting a different domain while in subdomain logs page (located in **user level** ->**Subdomain Management** ->**usage Log / error Log**) caused incorrect logs to be displayed.

To prevent inconsistent data, domain selector has been removed from this page.

## Improve protected directories validation evolution fix[​](https://docs.directadmin.com/changelog/version-1.702.html#improve-protected-directories-validation)

The validation for "Username" and "Realm" input fields (within protected directories page) was updated.

## Limit database name length to less than 64 characters evolution fix[​](https://docs.directadmin.com/changelog/version-1.702.html#limit-database-name-length-to-less-than-64-characters)

If attempting to create a database with a name that consists of more than 63 characters, validation error will be shown.

Widget "View more" link now correctly routes to plugins.

## Password-protected directory configuration for Nginx fix[​](https://docs.directadmin.com/changelog/version-1.702.html#password-protected-directory-configuration-for-nginx)

The protected directories configuration generator for the Nginx web server is updated to ensure special symbols in the directory name will not cause a malformed configuration file.

## cpanel restore: LetsEncrypt/ZeroSSL: ensure domain.com.cert.creation_time fix[​](https://docs.directadmin.com/changelog/version-1.702.html#cpanel-restore-letsencrypt-zerossl-ensure-domain-com-cert-creation-time)

When a cpanel backup is converted to a DirectAdmin backup before a restore, the .creation_time files were not being created, preventing auto-renewal of LetsEncrypt certificates. This fix creates the missing files during conversion.

## Race condition: users.list, reseller.list, admin.list fix[​](https://docs.directadmin.com/changelog/version-1.702.html#race-condition-users-list-reseller-list-admin-list)

Improved locking and logic for writing the `users.list`, `reseller.list`, `admin.list` files. It will mostly help those who make parallel API calls to create accounts, but also affects account creation via GUI and restores. Any errors with this new `add_to_list` will be logged in the `error.log` or `errortaskq.log` files, with strings starting with `add_to_list:%s: ...`, where the `%s` would represent the account that was to be added to the list, followed by the reason for the error (locking, reading, or writing). In addition to the better locking logic, should any lock fail to be obtained (which will be far less likely), it will trigger new `task.queue` commands to rebuild those lists:

```
action=rewrite&value=users.list&creator=fred
action=rewrite&value=reseller.list&creator=admin
action=rewrite&value=admin.list&creator=admin
```

where `creator` must be presenty for any of these rewrite types. The `creator` for the `users.list` variant can be a Reseller or Admin, and the `reseller.list` and `admin.list` must be an Admin.

## Cache available plugin version fix[​](https://docs.directadmin.com/changelog/version-1.702.html#cache-available-plugin-version)

Previously, available plugin version was fetched from `version_url` (stored in `plugin.conf`) any time Plugin Manager page was accessed.

The new (`GET /api/plugin-manager/plugins`) and legacy (`GET /CMD_PLUGIN_MANAGER`) API endpoints have been updated to cache available version for 30 minutes instead.

## Remove unused "Notify" checkbox from vacation message form evolution removal[​](https://docs.directadmin.com/changelog/version-1.702.html#remove-unused-notify-checkbox-from-vacation-message-form)

The "Notify" checkbox was removed from the Create Vacation Message form because it had no effect.

## Removed plugin installed state from Plugin Manager removal[​](https://docs.directadmin.com/changelog/version-1.702.html#removed-plugin-installed-state-from-plugin-manager)

Back in version [1.694](https://docs.directadmin.com/changelog/version-1.694.html#changes-to-plugins-uploaded-with-plugin-manager) we made plugin installation non-optional (successfully run plugin's `install.sh` script) when it's being uploaded. And back in version [1.700](https://docs.directadmin.com/changelog/version-1.700.html#plugin-manager-redesign) we hid the install/uninstall actions from Evolution. The idea was that there is no reason for install/uninstall to live as separate actions and that they should be a core part of plugin upload or deletion process.

With this change, we're dropping `installed` state (saved within `plugin.conf`) completely.

The following API endpoints are removed:

*   `POST /CMD_PLUGIN_MANAGER {"install": "yes"}`
*   `POST /CMD_PLUGIN_MANAGER {"uninstall": "yes"}`
*   `POST /api/plugin-manager/plugins/{id}/install`
*   `POST /api/plugin-manager/plugins/{id}/uninstall`

UI changes:

*   The following warning is removed from Evolution: "This plugin was added before installation was mandatory and currently is not installed."
*   Install/Uninstall buttons and state are no longer visible in Enhanced.

**If you have an uninstalled plugin** (install action was not performed when adding plugin before version 1.694 or installed state was set to no by executing uninstall action after plugin was uploaded), there are two options to install the plugin:

*   Execute `install.sh` script directly (which is found in `/usr/local/directadmin/plugins/{id}/scripts` folder)
*   Reupload the plugin.
