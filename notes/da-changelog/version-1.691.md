Title: Version 1.691 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.691.html

Markdown Content:
Released: 2025-12-17

*   [Hide .trash folder from the main list and folders tree in File Manager evolution update](https://docs.directadmin.com/changelog/version-1.691.html#hide-trash-folder-from-the-main-list-and-folders-tree-in-file-manager)
*   [Updated File Manager "Archive" dialog evolution update](https://docs.directadmin.com/changelog/version-1.691.html#updated-file-manager-archive-dialog)
*   [Improved loading and empty states in File Manager evolution update](https://docs.directadmin.com/changelog/version-1.691.html#improved-loading-and-empty-states-in-file-manager)
*   [Always use Systemd status for Service monitor update](https://docs.directadmin.com/changelog/version-1.691.html#always-use-systemd-status-for-service-monitor)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.691.html#software-version-changes)
*   [Display all email accounts in IMAPSync pages evolution fix](https://docs.directadmin.com/changelog/version-1.691.html#display-all-email-accounts-in-imapsync-pages)
*   [Fix issues with date formats page evolution fix](https://docs.directadmin.com/changelog/version-1.691.html#fix-issues-with-date-formats-page)
*   [CGroup not displaying very long usernames. fix](https://docs.directadmin.com/changelog/version-1.691.html#cgroup-not-displaying-very-long-usernames)
*   [Removed notice count from CMD_PLUGINS removal](https://docs.directadmin.com/changelog/version-1.691.html#removed-notice-count-from-cmd-plugins)
*   [Removed options field from domain-related API endpoints removal](https://docs.directadmin.com/changelog/version-1.691.html#removed-options-field-from-domain-related-api-endpoints)
*   [Removed clean_forwarders flag from CMD_POP_EMAIL?action=delete action removal](https://docs.directadmin.com/changelog/version-1.691.html#removed-clean-forwarders-flag-from-cmd-pop-email-action-delete-action)
*   [Removed add_apache_comments configuration option from directadmin.conf removal](https://docs.directadmin.com/changelog/version-1.691.html#removed-add-apache-comments-configuration-option-from-directadmin-conf)
*   [Removed process_list_debug configuration options from directadmin.conf removal](https://docs.directadmin.com/changelog/version-1.691.html#removed-process-list-debug-configuration-options-from-directadmin-conf)

## Hide `.trash` folder from the main list and folders tree in File Manager evolution update[​](https://docs.directadmin.com/changelog/version-1.691.html#hide-trash-folder-from-the-main-list-and-folders-tree-in-file-manager)

The `.trash` folder no longer is visible in the root listing or folder tree. Use the previously added and always visible `Trash Dir` button to review deleted items. Everything else about trash management stays the same.

## Updated File Manager "Archive" dialog evolution update[​](https://docs.directadmin.com/changelog/version-1.691.html#updated-file-manager-archive-dialog)

The archive dialog now calls a new API endpoint and reports any errors right in the same window, so you immediately know if one of the selected files or folders cannot be archived. The dialog name also changed from “Compress” to “Archive” to better match how most people describe this action.

## Improved loading and empty states in File Manager evolution update[​](https://docs.directadmin.com/changelog/version-1.691.html#improved-loading-and-empty-states-in-file-manager)

File Manager now shows loading indicators while fetching directory contents and displays a helpful message when a folder is empty, making it easier to understand what's happening.

## Always use Systemd status for Service monitor update[​](https://docs.directadmin.com/changelog/version-1.691.html#always-use-systemd-status-for-service-monitor)

Service Monitor will now use systemd status to determine if a watched service is active. It will only try to start the service if it is in an `inactive` or `failed` state.

Previously, it tried to determine the service status by trying to hunt for processes with the same name, with fallback to systemd. This system did not correctly account for transitional service states (`activating` or `deactivating`), causing superfluous restarts.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.691.html#software-version-changes)

*   **apache2.4** updated from `2.4.65` to `2.4.66`
*   **exim** updated from `4.99` to `4.99.1`
*   **ModSecurity** rules from **OWASP CRS** updated from `4.20.0` to `4.21.0`
*   **nginx** updated from `1.29.3` to `1.29.4`
*   **roundcubemail** updated from `1.6.11` to `1.6.12`

## Display all email accounts in IMAPSync pages evolution fix[​](https://docs.directadmin.com/changelog/version-1.691.html#display-all-email-accounts-in-imapsync-pages)

The "User" input found within IMAPSync Migrations import and export pages was limited. With this fix, all email users are always loaded and the ability to narrow down the list of users was added.

## Fix issues with date formats page evolution fix[​](https://docs.directadmin.com/changelog/version-1.691.html#fix-issues-with-date-formats-page)

The date formats page (located in **Customize Evolution Skin**) had multiple hard to spot bugs and inconsistencies that are now solved.

## CGroup not displaying very long usernames. fix[​](https://docs.directadmin.com/changelog/version-1.691.html#cgroup-not-displaying-very-long-usernames)

Truncation issue for very long usernames, if the `max_username_length` variable is increased to a value above the default. This fix will now scale the cgroup username length limit based on the above setting.

## Removed notice count from CMD_PLUGINS removal[​](https://docs.directadmin.com/changelog/version-1.691.html#removed-notice-count-from-cmd-plugins)

`CMD_PLUGINS_ADMIN`, `CMD_PLUGINS_RESELLER`, `CMD_PLUGINS` json response no longer returns any of the following:

*   `notice_count_url_admin`
*   `notice_count_url_reseller`
*   `notice_count_url_user`

## Removed `options` field from domain-related API endpoints removal[​](https://docs.directadmin.com/changelog/version-1.691.html#removed-options-field-from-domain-related-api-endpoints)

The following API endpoints will no longer have `options` field in the JSON response data:

*   `GET /CMD_ADDITIONAL_DOMAINS`
*   `GET /CMD_SHOW_DOMAIN?action=view`
*   `GET /CMD_SUBDOMAIN?action=show_docroot_override`

The `options` field used to contain an internal representation of the CustomBuild configuration. The same information about available PHP versions is available in other fields of the same response.

This field is removed because it used to expose excessive information. Also the and `option` field structure was not stable, it used to change over time depending on the internal DirectAdmin data structures.

## Removed `clean_forwarders` flag from `CMD_POP_EMAIL?action=delete` action removal[​](https://docs.directadmin.com/changelog/version-1.691.html#removed-clean-forwarders-flag-from-cmd-pop-email-action-delete-action)

Email account removal will now unconditionally [clean up forwarders](https://docs.directadmin.com/changelog/version-1.43.0.html#ability-to-clear-forwarder-values-when-deleting-emails) of deleted accounts.

## Removed `add_apache_comments` configuration option from `directadmin.conf`removal[​](https://docs.directadmin.com/changelog/version-1.691.html#removed-add-apache-comments-configuration-option-from-directadmin-conf)

Comments in the configuration files about the file being auto-generated will always be added.

## Removed `process_list_debug` configuration options from `directadmin.conf`removal[​](https://docs.directadmin.com/changelog/version-1.691.html#removed-process-list-debug-configuration-options-from-directadmin-conf)

This flag was used to debug service monitor to print all processes to error log. This debug output is no longer needed due to [changes to the service monitor](https://docs.directadmin.com/changelog/version-1.691.html#always-use-systemd-status-for-service-monitor)
