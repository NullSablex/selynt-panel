Title: Version 1.690 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.690.html

Published Time: Thu, 28 May 2026 08:00:01 GMT

Markdown Content:
Released: 2025-12-02

*   [Isolated PHP-FPM mode new](https://docs.directadmin.com/changelog/version-1.690.html#isolated-php-fpm-mode)
*   [File Manager action toolbar adapts to browser window size evolution update](https://docs.directadmin.com/changelog/version-1.690.html#file-manager-action-toolbar-adapts-to-browser-window-size)
*   [Updated File Manager "Copy" dialog evolution update](https://docs.directadmin.com/changelog/version-1.690.html#updated-file-manager-copy-dialog)
*   [Trash is now a separate page in File Manager evolution update](https://docs.directadmin.com/changelog/version-1.690.html#trash-is-now-a-separate-page-in-file-manager)
*   ["Move Users Between Resellers" UI update evolution update](https://docs.directadmin.com/changelog/version-1.690.html#move-users-between-resellers-ui-update)
*   [OpenLiteSpeed installation custombuild update](https://docs.directadmin.com/changelog/version-1.690.html#openlitespeed-installation)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.690.html#software-version-changes)
*   [Backup and restore for ModSecurity configuration update](https://docs.directadmin.com/changelog/version-1.690.html#backup-and-restore-for-modsecurity-configuration)
*   [New modsecurity_enabled configuration option in directadmin.conf update](https://docs.directadmin.com/changelog/version-1.690.html#new-modsecurity-enabled-configuration-option-in-directadmin-conf)
*   [Improved jailshell script update](https://docs.directadmin.com/changelog/version-1.690.html#improved-jailshell-script)
*   [Fix API based validation evolution fix](https://docs.directadmin.com/changelog/version-1.690.html#fix-api-based-validation)
*   [User-owned Redis services use UID-based instance names fix](https://docs.directadmin.com/changelog/version-1.690.html#user-owned-redis-services-use-uid-based-instance-names)
*   [The CLI=1 option in domain.conf is no longer used removal](https://docs.directadmin.com/changelog/version-1.690.html#the-cli-1-option-in-domain-conf-is-no-longer-used)
*   ["Select All" option removed from group selection evolution removal](https://docs.directadmin.com/changelog/version-1.690.html#select-all-option-removed-from-group-selection)
*   [Removed cloud_cache configuration option from directadmin.conf removal](https://docs.directadmin.com/changelog/version-1.690.html#removed-cloud-cache-configuration-option-from-directadmin-conf)
*   [Protected directories add improvements evolution update](https://docs.directadmin.com/changelog/version-1.690.html#protected-directories-add-improvements)
    *   [Before the changes](https://docs.directadmin.com/changelog/version-1.690.html#before-the-changes)
    *   [After the changes](https://docs.directadmin.com/changelog/version-1.690.html#after-the-changes)

## Isolated PHP-FPM mode new[​](https://docs.directadmin.com/changelog/version-1.690.html#isolated-php-fpm-mode)

The PHP-FPM integration has a new integration mechanism called the isolated PHP-FPM. In isolated PHP-FPM, each user account gets a dedicated PHP-FPM service. This allows PHP-FPM to be executed in a jailed environment and achieves a complete isolation of execution between different user accounts.

Key improvements of the isolated FPM compared to the standard FPM:

*   **Security**. The FPM process is executed in an environment created by jailshell. This means PHP code does not have access to the server process list and file system. It runs in an isolated lightweight container where only user-owned files and explicitly allowed files are visible. Same environment users get when using jailshell.
*   **Data isolation**. Each user has their own FPM master process. This ensured no data sharing or leaking is possible between different users. Old FPM mode has a single shared master process that shares opcache between different users.
*   **Resource control**. The FPM processes (both master process and worker process) are executed inside the resource limits cgroup configured for the user. It means the limits are applied even on the master process that used to be shared between multiple users in the old FPM mode. A single user that would be throttled for excessive resource usage can no longer impact other users on the server.
*   **Speed**. In this mode the execution of PHP scripts has no performance penalty for the security features. It works faster than OpenLiteSpeed lsphp, Apache FastCGI, and even non-isolated PHP-FPM mode.

All the benefits for the new mode come with an increase in the total memory consumption. The server should have enough memory to allow each user to have a separate FPM process. A single user could have multiple PHP-FPM processes when multiple PHP versions are in use (separate FPM process per PHP version). The PHP-FPM is patched to terminate after 10 minutes of inactivity.

The isolated PHP-FPM mode at the moment is an opt-in feature that is enabled with the special `isolated_fpm=1` flag in `directadmin.conf`. To test out the new mode, it is enough to execute the following commands:

sh

```
da config-set isolated_fpm 1 --restart
da build php
```

**Note**: The isolated FPM is activated only for the user accounts that use jailshell (the **Jailed** check box in the user configuration page).

## File Manager action toolbar adapts to browser window size evolution update[​](https://docs.directadmin.com/changelog/version-1.690.html#file-manager-action-toolbar-adapts-to-browser-window-size)

The file/folder action toolbar now automatically fits as many action buttons as possible based on your browser width. Extra actions move into the "More" dropdown. This reduces wasted space and makes common actions easier to reach on both large and small screens.

## Updated File Manager "Copy" dialog evolution update[​](https://docs.directadmin.com/changelog/version-1.690.html#updated-file-manager-copy-dialog)

The copy dialog now uses a new API endpoint, supports copying one or multiple selected files or folders in a single action, and shows operational errors in the same dialog. With this update, the old Duplicate action has been also removed.

## Trash is now a separate page in File Manager evolution update[​](https://docs.directadmin.com/changelog/version-1.690.html#trash-is-now-a-separate-page-in-file-manager)

The trash view in File Manager has been improved to make cleanup easier:

1.   Trash opens on its own page, separate from your main files, making it easier to access and manage deleted items.
2.   The “Trash Dir” item in the left sidebar is always visible for quick access from anywhere inside File Manager.
3.   Trashed folders include a new "View contents” action that takes you to the main File Manager to browse what’s inside before you restore or permanently delete.

## "Move Users Between Resellers" UI update evolution update[​](https://docs.directadmin.com/changelog/version-1.690.html#move-users-between-resellers-ui-update)

The "Move Users Between Resellers" page (located in **admin level**, **Account Manager** category) was updated. It now gives clear instructions of what steps need to be taken in order to move users.

## OpenLiteSpeed installation custombuild update[​](https://docs.directadmin.com/changelog/version-1.690.html#openlitespeed-installation)

Previous OpenLiteSpeed versions were installed on top of older installations, often leaving behind legacy files that caused unpredictable side effects. The installation process has now been rewritten to always perform a clean install. If the preparation phase encounters any issues, the process exits early without stopping the running web server.

To enable minimal-downtime upgrades, two core changes were introduced:

**1. Log file changes:**

*   Logs of the admin interface from the `/usr/local/lsws/admin/logs` have been moved to `/var/log/openlitespeed`.
*   A dedicated logrotate configuration for openlitespeed has been added.

**2. Configuration file changes:**

*   Configuration files have moved from `/usr/local/lsws/conf` to `/etc/openlitespeed`.
*   Only files that we provide can be overriden: 
    *   Old behavior: Copy everything from the `custom/openlitespeed/conf/*`.
    *   New behavior: Only the filenames that exist in `configure/openlitespeed/conf/` are copied from the `custom/openlitespeed/conf/`.

*   A new drop-in directory `configure/openlitespeed/conf.d/` has been added. Everything from the `custom/openlitespeed/conf.d/` will get copied over `/etc/openlitespeed/conf.d/` and automatically included via wildcard include in `httpd_config.conf`.
*   A new config override option for the OpenLiteSpeed admin configuration has been added: `configure/openlitespeed/admin/admin_config.conf`

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.690.html#software-version-changes)

*   **composer** updated from `2.8.12` to `2.9.2`
*   **exim** updated from `4.98.2` to `4.99`
*   **imagick** (PHP extension) updated from `3.8.0` to `3.8.1`
*   **litespeed** updated from `6.3.4-7` to `6.3.4-8`
*   **MariaDB 11.8** updated from `11.8.4` to `11.8.5`
*   **mod_lsapi** updated from `1.1-81` to `1.1-86`
*   **PHP 8.3** updated from `8.3.27` to `8.3.28`
*   **PHP 8.4** updated from `8.4.14` to `8.4.15`
*   **PHP 8.5** updated from `8.5.0RC4` to `8.5.0`
*   **redis** updated from `8.2.3` to `8.4.0`
*   **xapian-core** updated from `1.4.29` to `1.4.30`

## Backup and restore for ModSecurity configuration update[​](https://docs.directadmin.com/changelog/version-1.690.html#backup-and-restore-for-modsecurity-configuration)

If a domain or subdomain uses a non-standard ModSecurity configuration, the configuration will be included in the user account backup files.

Performing a restore operation on the backup will restore the ModSecurity configuration if the backup file contains it.

## New `modsecurity_enabled` configuration option in `directadmin.conf`update[​](https://docs.directadmin.com/changelog/version-1.690.html#new-modsecurity-enabled-configuration-option-in-directadmin-conf)

This new configuration option controls if the web server templates should include the configuration directives for ModSecurity.

Server administrators do not really need to care about this option. The CustomBuild will automatically set this option to the correct value when ModSecurity is being used.

## Improved jailshell script update[​](https://docs.directadmin.com/changelog/version-1.690.html#improved-jailshell-script)

The jailshell script has the following changes:

*   Use `--as-pid-1` parameter when starting the `bwrap`. This starts only one `bwrap` process instead of two and keeps bash as the PID 1 process inside the jailed container. Users from inside the jail will no longer see the `bwrap` process in the process list.
*   Make sure `/var/run` exists inside the jailed container.
*   Do not try exposing `/home/mysql/mysql.sock` inside the jailed container.
*   The `/tmp/mysql.sock` file inside the jailed container will always be linked to `/var/lib/mysql/mysql.sock` outside the jailed container.
*   Expose the `/run/systemd/notify` socket inside the jailed container. This socket is used for jailed systemd services.

## Fix API based validation evolution fix[​](https://docs.directadmin.com/changelog/version-1.690.html#fix-api-based-validation)

Inputs were not being validated in multiple pages. This includes pages such as user/reseller/admin creation, package creation, domain creation and more.

## User-owned Redis services use UID-based instance names fix[​](https://docs.directadmin.com/changelog/version-1.690.html#user-owned-redis-services-use-uid-based-instance-names)

The service instance name for user-owned Redis instances has changed from `redis@{username}.service` to `redis@{UID}.service`.

This service rename allows us to rely on systemd to manage service placement into resource control groups. This fixes the cgroups permission bug that used to cause systemd error messages when starting a user systemd instance.

Example error messages:

```
systemd[3584620]: Failed to create /user.slice/user-1000.slice/user@1000.service/init.scope control group: Permission denied
systemd[3584620]: Failed to allocate manager object: Permission denied
```

**Note**: If the Redis service file was customised (`redis@.service` or `redis_lve@.service`), please make sure to update the custom service file to use UID-based instance names.

## The `CLI=1` option in `domain.conf` is no longer used removal[​](https://docs.directadmin.com/changelog/version-1.690.html#the-cli-1-option-in-domain-conf-is-no-longer-used)

Adding the `CLI=1` line in the domain configuration file will be ignored. It used to be possible to force generating Apache configuration files for `mod_php` by manually adding this line in the domain configuration file. The `mod_php` integration is no longer supported, and this feature is removed.

## "Select All" option removed from group selection evolution removal[​](https://docs.directadmin.com/changelog/version-1.690.html#select-all-option-removed-from-group-selection)

The "Select All" option was removed from the following:

*   User selection within "Move Users Between Resellers" page.
*   User selection within "Admin Backup/Transfer" "modify" and "schedule" pages. All users can instead be selected by ticking the "All Users" option located at the top of `Step 1: Who`.

## Removed `cloud_cache` configuration option from `directadmin.conf`removal[​](https://docs.directadmin.com/changelog/version-1.690.html#removed-cloud-cache-configuration-option-from-directadmin-conf)

This option will always be enabled.

## Protected directories add improvements evolution update[​](https://docs.directadmin.com/changelog/version-1.690.html#protected-directories-add-improvements)

Updated the protected directories view with a modernized tree selector featuring improved accessibility and full keyboard navigation support.

### Before the changes [​](https://docs.directadmin.com/changelog/version-1.690.html#before-the-changes)

![Image 1: Old add protected directory](https://docs.directadmin.com/assets/protected-add-before.FMuj2PO0.png)

### After the changes [​](https://docs.directadmin.com/changelog/version-1.690.html#after-the-changes)

![Image 2: Old add protected directory](https://docs.directadmin.com/assets/protected-add-after.Bko-IvlW.png)
