Title: Version 1.695 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.695.html

Markdown Content:
Released: 2026-02-18

*   [Improve File Manager keyboard navigation evolution update](https://docs.directadmin.com/changelog/version-1.695.html#improve-file-manager-keyboard-navigation)
*   [Add File Manager edit shortcuts evolution update](https://docs.directadmin.com/changelog/version-1.695.html#add-file-manager-edit-shortcuts)
*   [Use DirectAdmin User-Agent for HTTP requests update](https://docs.directadmin.com/changelog/version-1.695.html#use-directadmin-user-agent-for-http-requests)
*   [Enable secure access group option automatically update](https://docs.directadmin.com/changelog/version-1.695.html#enable-secure-access-group-option-automatically)
*   [Default PHP Opcache extension configuration will not block API access update](https://docs.directadmin.com/changelog/version-1.695.html#default-php-opcache-extension-configuration-will-not-block-api-access)
*   [‼️ Web server configuration templates always use public_html directory update](https://docs.directadmin.com/changelog/version-1.695.html#%EF%B8%8F-web-server-configuration-templates-always-use-public-html-directory)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.695.html#software-version-changes)
*   [Fix git deploy crash fix](https://docs.directadmin.com/changelog/version-1.695.html#fix-git-deploy-crash)
*   [Plugin Manger script permissions fix](https://docs.directadmin.com/changelog/version-1.695.html#plugin-manger-script-permissions)
*   [Cluster: cluster_domainowners: allow master to create subdomain under same User fix](https://docs.directadmin.com/changelog/version-1.695.html#cluster-cluster-domainowners-allow-master-to-create-subdomain-under-same-user)
*   [Rspamd: mime_whitelist was using 'from' instead of 'from_mime' fix](https://docs.directadmin.com/changelog/version-1.695.html#rspamd-mime-whitelist-was-using-from-instead-of-from-mime)
*   [Removed custom menu names evolution removal](https://docs.directadmin.com/changelog/version-1.695.html#removed-custom-menu-names)
*   [Removed config.json maintenance task evolution removal](https://docs.directadmin.com/changelog/version-1.695.html#removed-config-json-maintenance-task)
*   [Removed reseller date formats customizations evolution removal](https://docs.directadmin.com/changelog/version-1.695.html#removed-reseller-date-formats-customizations)
*   [Drop sleep parameter from taskq action=rewrite removal](https://docs.directadmin.com/changelog/version-1.695.html#drop-sleep-parameter-from-taskq-action-rewrite)

## Improve File Manager keyboard navigation evolution update[​](https://docs.directadmin.com/changelog/version-1.695.html#improve-file-manager-keyboard-navigation)

The File Manager components (Main toolbar and breadcrumbs) have been improved for better accessibility. Users can now more easily navigate these elements using keyboard shortcuts, with enhanced tab navigation and improved focus indicators to show which element is currently selected.

## Add File Manager edit shortcuts evolution update[​](https://docs.directadmin.com/changelog/version-1.695.html#add-file-manager-edit-shortcuts)

New "Save file" and "Reload file" shortcuts are now available. A shortcuts popover has also been added to show the main file editor shortcuts to users.

![Image 1: File edit keyboard shortcuts popover](https://docs.directadmin.com/assets/keyboard-shortcuts-popover.DcBQyKgP.png)

## Use DirectAdmin User-Agent for HTTP requests update[​](https://docs.directadmin.com/changelog/version-1.695.html#use-directadmin-user-agent-for-http-requests)

HTTP requests made by DirectAdmin daemon now report `User-Agent: DirectAdmin/1.695` (with correct DirectAdmin version).

## Enable secure access group option automatically update[​](https://docs.directadmin.com/changelog/version-1.695.html#enable-secure-access-group-option-automatically)

An automatic migration is added to enable the secure access group option and make sure the name of the secure access group is `access`.

The secure access group option makes web, email, and ftp services be part of the UNIX group `access`. This option has been enabled by default since DirectAdmin 1.33.3 (released 2009-04-05) for new server installations. However, very old servers might still have this option disabled.

This migration prepares all servers for this option to be mandatory in the upcoming releases.

**Note**: This migration will also make sure the secure access group name is set to `access`. On servers where this group had a different name, the group name will be changed to `access`.

## Default PHP Opcache extension configuration will not block API access update[​](https://docs.directadmin.com/changelog/version-1.695.html#default-php-opcache-extension-configuration-will-not-block-api-access)

The file `custombuild/configure/opcache/opcache.ini` is updated to no longer block opcache API access.

## ‼️ Web server configuration templates always use `public_html` directory update[​](https://docs.directadmin.com/changelog/version-1.695.html#%EF%B8%8F-web-server-configuration-templates-always-use-public-html-directory)

The web server configuration templates are updated to always use the `public_html` as the root directory for each virtual host. Before this release, the `private_html` directory was used for connections over TLS.

This change makes sure the same files will be served for the same hostname regardless of TLS being used or not.

Affected template files:

*   `data/templates/nginx_server_secure.conf`
*   `data/templates/nginx_server_secure_sub.conf`
*   `data/templates/openlitespeed_vhost.conf`
*   `data/templates/virtual_host2_secure.conf`
*   `data/templates/virtual_host2_secure_sub.conf`

**Note**: This is a breaking change if `public_html` and `private_html` directories are not yet merged. Please use the **Ensure all domains private document roots link to public** maintenance task (Admin level menu entry in Evolution) to check if there are users that can be affected.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.695.html#software-version-changes)

*   **MariaDB 10.11** updated from `10.11.15` to `10.11.16`
*   **MariaDB 10.6** updated from `10.6.24` to `10.6.25`
*   **MariaDB 11.4** updated from `11.4.9` to `11.4.10`
*   **MariaDB 11.8** updated from `11.8.5` to `11.8.6`
*   **ModSecurity** rules from **OWASP CRS** updated from `4.22.0` to `4.23.0`
*   **nginx** updated from `1.29.4` to `1.29.5`
*   **ngx_cache_purge** updated from `2.5.5` to `2.5.6`
*   **PHP 8.4** updated from `8.4.17` to `8.4.18`
*   **PHP 8.5** updated from `8.5.2` to `8.5.3`
*   **redis** updated from `8.4.0` to `8.6.0`
*   **roundcubemail** updated from `1.6.12` to `1.6.13`

## Fix git deploy crash fix[​](https://docs.directadmin.com/changelog/version-1.695.html#fix-git-deploy-crash)

Git feature deploy action used to crash abruptly. This is now fixed.

## Plugin Manger script permissions fix[​](https://docs.directadmin.com/changelog/version-1.695.html#plugin-manger-script-permissions)

If any of the scripts located inside plugin's `scripts` folder do not have execute permissions, they'll be added as necessary.

## Cluster: cluster_domainowners: allow master to create subdomain under same User fix[​](https://docs.directadmin.com/changelog/version-1.695.html#cluster-cluster-domainowners-allow-master-to-create-subdomain-under-same-user)

If the hosting master has `check_subdomain_owner=1` and the dns slave has `check_subdomain_owner_in_cluster_domainowners=1`, if User `fred` has `fred.com`, the bug was that this User account would not be able to create a new domain called `sub.fred.com`. This fix uses the existing returned hostname and User values from the slave, such that the master can validate if the current User is allowed to create the current hostname. It would have previuosly returned the incorrect `Domain exists on 1.2.3.4` when trying to create a subdomain as a full domain, where the full domain itself exists in the slave's cluster_domainowners file. As before, the slave still returns that the value already exists, because of `check_subdomain_owner_in_cluster_domainowners=1` with status `exists=3`, which refers to the subdomain match for a higher-level domain name, including the `hostname` and `username`, during the Cluster's `CMD_API_DNS_ADMIN?action=exists&domain=fred.com&check_for_parent_domain=true` check. (The fix is in the code on the master side)

## Rspamd: mime_whitelist was using 'from' instead of 'from_mime' fix[​](https://docs.directadmin.com/changelog/version-1.695.html#rspamd-mime-whitelist-was-using-from-instead-of-from-mime)

The per-user rspamd config uses 2 sections for each whitelist and blacklists. One uses the "from" format matches the smtp sender and the "from_mime" matches the mime sender. The whitelist section was using "from" instead of "from_mime".

## Removed custom menu names evolution removal[​](https://docs.directadmin.com/changelog/version-1.695.html#removed-custom-menu-names)

Custom menu entry names can no longer be configured within "Customize Evolution Skin" page. Any previously set custom names will revert to defaults.

## Removed config.json maintenance task evolution removal[​](https://docs.directadmin.com/changelog/version-1.695.html#removed-config-json-maintenance-task)

The migration task titled "Migrate legacy Evolution customizations to new format" was dropped.

## Removed reseller date formats customizations evolution removal[​](https://docs.directadmin.com/changelog/version-1.695.html#removed-reseller-date-formats-customizations)

Removed "Date Formats" from "Customize Evolution Skin". Formats were moved to user options and can be changed or reset in the "Skin Options" page, "Date Formats" section.

## Drop sleep parameter from taskq action=rewrite removal[​](https://docs.directadmin.com/changelog/version-1.695.html#drop-sleep-parameter-from-taskq-action-rewrite)

Optional `sleep` parameter is no longer supported for dataskq `action=rewrite` actions. For compatibility `sleep` parameter is now ignored as if it did not exist.
