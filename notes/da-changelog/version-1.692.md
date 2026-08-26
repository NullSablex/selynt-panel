Title: Version 1.692 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.692.html

Markdown Content:
Released: 2026-01-05

*   [New "Clear trash" action in File Manager evolution update](https://docs.directadmin.com/changelog/version-1.692.html#new-clear-trash-action-in-file-manager)
*   [Updated File Manager "Move" dialog evolution update](https://docs.directadmin.com/changelog/version-1.692.html#updated-file-manager-move-dialog)
*   [Faster cleanup for long-running plugin requests update](https://docs.directadmin.com/changelog/version-1.692.html#faster-cleanup-for-long-running-plugin-requests)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.692.html#software-version-changes)
*   [Simplified web server and PHP-FPM templates update](https://docs.directadmin.com/changelog/version-1.692.html#simplified-web-server-and-php-fpm-templates)
*   [Fix checkmark for selected domain evolution fix](https://docs.directadmin.com/changelog/version-1.692.html#fix-checkmark-for-selected-domain)
*   [Fix table sorting for tables with initial sort evolution fix](https://docs.directadmin.com/changelog/version-1.692.html#fix-table-sorting-for-tables-with-initial-sort)
*   [Removed file or folder creation and upload actions from trash in File Manager evolution fix](https://docs.directadmin.com/changelog/version-1.692.html#removed-file-or-folder-creation-and-upload-actions-from-trash-in-file-manager)
*   [Show all pointer/alias domain combinations in new certificate request page fix](https://docs.directadmin.com/changelog/version-1.692.html#show-all-pointer-alias-domain-combinations-in-new-certificate-request-page)
*   [Custom Package Items in php-fpm.conf and VirtualHost templates](https://docs.directadmin.com/changelog/version-1.692.html#custom-package-items-in-php-fpm-conf-and-virtualhost-templates)
*   [Removed script output from successful CMD_PLUGIN_MANAGER install action removal](https://docs.directadmin.com/changelog/version-1.692.html#removed-script-output-from-successful-cmd-plugin-manager-install-action)
*   [Removed named_service_override configuration options from directadmin.conf removal](https://docs.directadmin.com/changelog/version-1.692.html#removed-named-service-override-configuration-options-from-directadmin-conf)
*   [Removed CustomBuild set_service command removal](https://docs.directadmin.com/changelog/version-1.692.html#removed-custombuild-set-service-command)

## New "Clear trash" action in File Manager evolution update[​](https://docs.directadmin.com/changelog/version-1.692.html#new-clear-trash-action-in-file-manager)

A new "Clear Trash" action has been added to File Manager, letting you permanently delete all trashed files and folders conveniently.

## Updated File Manager "Move" dialog evolution update[​](https://docs.directadmin.com/changelog/version-1.692.html#updated-file-manager-move-dialog)

The move dialog now calls a new API endpoint and reports any errors right in the same window, so you immediately know if one of the selected files or folders cannot be moved.

## Faster cleanup for long-running plugin requests update[​](https://docs.directadmin.com/changelog/version-1.692.html#faster-cleanup-for-long-running-plugin-requests)

Long-running plugin requests used to continue running until the plugin process terminates.

If the client request for the plugin is cancelled, the plugin handler would not notice that and would continue to run.

An optimization is added to close the plugin request writing socket as soon as the client request is terminated. This allows plugin processes to detect output write errors and terminate faster.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.692.html#software-version-changes)

*   **composer** updated from `2.9.2` to `2.9.3`
*   **imapsync** updated from `2.290` to `2.314`
*   **phalcon** (PHP extension) updated from `5.9.3` to `5.10.0`
*   **PHP 8.1** updated from `8.1.33` to `8.1.34`
*   **PHP 8.2** updated from `8.2.29` to `8.2.30`
*   **PHP 8.3** updated from `8.3.28` to `8.3.29`
*   **PHP 8.4** updated from `8.4.15` to `8.4.16`
*   **PHP 8.5** updated from `8.5.0` to `8.5.1`

## Simplified web server and PHP-FPM templates update[​](https://docs.directadmin.com/changelog/version-1.692.html#simplified-web-server-and-php-fpm-templates)

PHP-FPM configuration files are updated to no longer use the `LIMIT_EXTENSIONS` token.

The PHP-FPM option `security.limit_extensions` now has a static value that matches the file extensions web server will pass to the PHP-FPM process.

Files:

*   `data/templates/php-fpm.conf`
*   `data/templates/php-isolated-fpm.conf`

diff

```
@@ -20,6 +20,8 @@ pm.max_children = |MAX_CHILDREN|
 pm.max_children = |MAX_CHILDREN|
 pm.process_idle_timeout = 20
 pm.max_requests = |MAX_REQUESTS|
 
+security.limit_extensions = .php .inc .phtml
+
 php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f |EMAIL|
 
 |*if PHP_SESSION_SAVE_PATH!=""|
@@ -33,10 +35,6 @@ php_admin_value[open_basedir] = |OPEN_BASEDIR_PATH|
 php_admin_value[mail.log] = |PHP_MAIL_LOG_DIR|/php-mail.log
 |*endif|
 
-|*if LIMIT_EXTENSIONS!=""|
-security.limit_extensions = |LIMIT_EXTENSIONS|
-|*endif|
-
 |FPM_PHP_SETTINGS|
 
 |CUSTOM2|
```

The web server templates are simplified to use same set of PHP file extensions. The `.phps` files were matched with the `FilesMatch` directive, but ignored in the `AddHandler` directive.

Files:

*   `data/templates/user_virtual_host.conf`

diff

```
<Directory "|HOME|/public_html">
        |*if HAVE_PHP1_FPM="1"|
-               <FilesMatch "\.(inc|php|phtml|phps)$">
+               <FilesMatch "\.(php|inc|phtml)$">
                        AddHandler "proxy:unix:|PHP_FPM_SOCKET_PATH||fcgi://localhost" .inc .php .phtml
                </FilesMatch> 
                <FilesMatch "\.(php53|php54|php55|php56|php70|php71|php72|php73|php74|php80|php81|php82)$">
```

Files:

*   `data/templates/virtual_host2.conf`
*   `data/templates/virtual_host2_secure.conf`
*   `data/templates/virtual_host2_sub.conf`
*   `data/templates/virtual_host2_secure_sub.conf`

diff

```
Options -ExecCGI -Includes +IncludesNOEXEC
 |*endif|
 |*if HAVE_PHP1_FPM="1"|
-               <FilesMatch "\.(inc|php|phtml|phps|php)$">
+               <FilesMatch "\.(php|inc|phtml)$">
                        <If "-f %{REQUEST_FILENAME}">
                                AddHandler "proxy:unix:|PHP_FPM_SOCKET_PATH||fcgi://localhost" .inc .php .phtml
                        </If>
```

## Fix checkmark for selected domain evolution fix[​](https://docs.directadmin.com/changelog/version-1.692.html#fix-checkmark-for-selected-domain)

Checkmark was not visible if the selected domain had non-latin letters in the name.

## Fix table sorting for tables with initial sort evolution fix[​](https://docs.directadmin.com/changelog/version-1.692.html#fix-table-sorting-for-tables-with-initial-sort)

Fixed an issue where tables that had initial sort could not be sorted any other way.

## Removed file or folder creation and upload actions from trash in File Manager evolution fix[​](https://docs.directadmin.com/changelog/version-1.692.html#removed-file-or-folder-creation-and-upload-actions-from-trash-in-file-manager)

The trash folder no longer shows "New Folder", "New File", or "Upload" actions. Since trash is meant only for restoring or permanently deleting items, these actions have been removed to avoid confusion.

## Show all pointer/alias domain combinations in new certificate request page fix[​](https://docs.directadmin.com/changelog/version-1.692.html#show-all-pointer-alias-domain-combinations-in-new-certificate-request-page)

The page for the new domain certificate is fixed to list out all domain pointer/alias and subdomain combinations. Previous DA versions would only show the main domain/alias host.

## Custom Package Items in php-fpm.conf and VirtualHost templates [​](https://docs.directadmin.com/changelog/version-1.692.html#custom-package-items-in-php-fpm-conf-and-virtualhost-templates)

For anyone who uses the [Custom Domain Items or Custom Package Items](https://docs.directadmin.com/directadmin/customizing-workflow/#custom-domain-package-items), their values will now be more readibly available in the php-fpmXX.conf files and Apache VirtualHost templates. The Custom Domain Items were [already available in the VirtualHosts](https://docs.directadmin.com/changelog/version-1.51.4.html#custom-domain-items-values-available-in-virtual-host2-conf-templates), but Custom Package Items have now been added, with the format:

`|CUSTOM_PACKAGE_ITEM_test|`

where `test` would be the name of the Custom Package Item.

Similarly, the `php-fpm.conf` template, which writes to, eg: `/usr/local/directadmin/data/users/fred/php/php-fpm83.conf`, also has support for Custom Package Items.

Note that custom CUSTOM_PACKAGE/DOMAIN_ITEM_ tokens are only generated if there is a matching field in their respective user.conf or domain.com.conf files.

## Removed script output from successful CMD_PLUGIN_MANAGER install action removal[​](https://docs.directadmin.com/changelog/version-1.692.html#removed-script-output-from-successful-cmd-plugin-manager-install-action)

Successful plugin installation using `CMD_PLUGIN_MANAGER` no longer returns script output if the script completes successfully. Script output will still be shown if the script fails.

## Removed `named_service_override` configuration options from `directadmin.conf`removal[​](https://docs.directadmin.com/changelog/version-1.692.html#removed-named-service-override-configuration-options-from-directadmin-conf)

This flag was intended to handle named service name mismatch between RHEL and Debian systems. Since Debian 11, both systems have decided to use `named.service` name.

## Removed CustomBuild `set_service` command removal[​](https://docs.directadmin.com/changelog/version-1.692.html#removed-custombuild-set-service-command)

The command `da build set_service` is not supported anymore. This command allowed changes to be made to the `/usr/local/directadmin/data/admin/services.status` file.

Command was removed because it falls out of scope for the functionality that the CustomBuild tool provides (installation and configuration additional software).

The services file can be easily managed manually or with an external helper script `set_service.sh`:

bash

```
#!/bin/bash

FILE=/usr/local/directadmin/data/admin/services.status
SERVICE=$(sed 's/[.[\*^\/&$]/\\&/g' <<< "$1")
SERVICE_RAW=$1
ACTION=$2

if [ "${ACTION}" = "ON" ] || [ "${ACTION}" = "OFF" ]; then
    if ! grep -q -e "^${SERVICE}=" ${FILE}; then
        echo "${SERVICE_RAW}=${ACTION}" >> ${FILE}
    else
        sed -i -e "s/^${SERVICE}=.*/${SERVICE}=${ACTION}/" ${FILE}
    fi
elif [ "${ACTION}" = "delete" ]; then
        sed -i -e "/^${SERVICE}=/d" ${FILE}
else
    echo "unknown option: ${ACTION}"
    echo "Usage:"
    echo "  set_service <service> ON"
    echo "  set_service <service> OFF"
    echo "  set_service <service> delete"
fi
```
