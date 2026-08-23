Title: Version 1.694 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.694.html

Markdown Content:
Released: 2026-02-03

*   [Support for the new DNS record types HTTPS and SVCB new](https://docs.directadmin.com/changelog/version-1.694.html#support-for-the-new-dns-record-types-https-and-svcb)
*   [Support for installing the Unbound DNS server new custombuild](https://docs.directadmin.com/changelog/version-1.694.html#support-for-installing-the-unbound-dns-server)
*   [File Manager remove file action hook new](https://docs.directadmin.com/changelog/version-1.694.html#file-manager-remove-file-action-hook)
*   [File Manager file editor redesign evolution update](https://docs.directadmin.com/changelog/version-1.694.html#file-manager-file-editor-redesign)
*   [New options.conf items new custombuild](https://docs.directadmin.com/changelog/version-1.694.html#new-options-conf-items)
*   [Updated service monitoring page evolution update](https://docs.directadmin.com/changelog/version-1.694.html#updated-service-monitoring-page)
*   [Changes to plugins uploaded with Plugin Manager update](https://docs.directadmin.com/changelog/version-1.694.html#changes-to-plugins-uploaded-with-plugin-manager)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.694.html#software-version-changes)
*   [Avoid double email delivery with broken forwarder configuration fix](https://docs.directadmin.com/changelog/version-1.694.html#avoid-double-email-delivery-with-broken-forwarder-configuration)
*   [File Manager checks directory access before navigating evolution fix](https://docs.directadmin.com/changelog/version-1.694.html#file-manager-checks-directory-access-before-navigating)
*   [Cannot edit JSON files in File Manager evolution fix](https://docs.directadmin.com/changelog/version-1.694.html#cannot-edit-json-files-in-file-manager)
*   [Updated systemd socket configuration for isolated PHP-FPM mode fix](https://docs.directadmin.com/changelog/version-1.694.html#updated-systemd-socket-configuration-for-isolated-php-fpm-mode)
*   [Removed tokens from custom menu entries evolution removal](https://docs.directadmin.com/changelog/version-1.694.html#removed-tokens-from-custom-menu-entries)
*   [Support for the SPF DNS resource record type removal](https://docs.directadmin.com/changelog/version-1.694.html#support-for-the-spf-dns-resource-record-type)
*   [Removed SpamAssassin update frequency setting custombuild removal](https://docs.directadmin.com/changelog/version-1.694.html#removed-spamassassin-update-frequency-setting)

## Support for the new DNS record types HTTPS and SVCB new[​](https://docs.directadmin.com/changelog/version-1.694.html#support-for-the-new-dns-record-types-https-and-svcb)

A new DNS resource record types - HTTPS and SVCB ([RFC 9460](https://datatracker.ietf.org/doc/html/rfc9460)) is supported by DirectAdmin. These DNS records enables the following features:

*   Redirect HTTPS service to other host name (alias mode).
*   Inform web browsers about HTTPS support and pass extra HTTPS parameters (service mode).
*   Allow storing ECH data in the DNS.

The availability of the new DNS record type in the user interface can be managed with a new `dns_https` and `dns_svcb` configuration options. Support for the new record types are enabled by default.

The default DNS HTTPS record set for new domains can be configured by creating a customised copy of the `data/templates/dns_https.conf` template file or `data/templates/dns_svcb.conf` template file.

![Image 1: New HTTPS record (alias mode)](https://docs.directadmin.com/assets/new-https-alias-record.O3y0mFZ9.png)![Image 2: New HTTPS record (service mode)](https://docs.directadmin.com/assets/new-https-service-record.BXJ3nfoi.png)

## Support for installing the Unbound DNS server new custombuild[​](https://docs.directadmin.com/changelog/version-1.694.html#support-for-installing-the-unbound-dns-server)

The CustomBuild tool now supports installing Unbound. Unbound is a validating, recursive, caching DNS resolver. Running it locally on the server can bring multiple advantages:

*   No need to configure DNS servers. The server can work without specifying the address of an external DNS server.
*   Guaranteed DNSSEC validation. Unbound DNS resolver uses DNSSEC by default. External DNS servers might support or might not support DNSSEC validation. It really depends on the ISP or DC network administrators.
*   Improved privacy. DNS lookups will contact authoritative servers directly. This removes an easy way to monitor server activity on the recursive DNS server level. Multiple name lookups will not be visible on the network at all because of the local DNS cache.
*   Zero trust. There are no 3rd party servers that could perform DNS response tampering for domains that use DNSSEC. Any response tampering would be detected by the DNSSEC validation logic.
*   Avoids popular spam RBL rate limiting. For example, the Spamhaus Project blocks access to its RBLs when public DNS servers are used (for example, Google, Cloudflare, Quad9, etc.).

Installing the Unbound DNS server can be enabled by setting the `unbound=yes` option in the `options.conf` file.

When CustomBuild installs the Unbound DNS server, it configures it to listen for the DNS requests on the `127.0.0.253` loopback IP address. This prevents the Unbound service from clashing with the Bind authoritative DNS server or the systemd-resolved stub resolver.

To enable and install the Unbound DNS server, use the following commands:

sh

```
da build set unbound yes
da build unbound
```

**Note**: CustomBuild will not automatically reconfigure the system to start using the Unbound resolver as the default system resolver.

There is a separate feature for starting to use the Unbound DNS server as main system resolver. It is controlled with the `unbound_as_default_resolver` option in the `options.conf` file.

To install the Unbound DNS server and start using it as default server resolver, use the following commands:

sh

```
da build set unbound yes
da build set unbound_as_default_resolver yes
da build unbound
```

## File Manager remove file action hook new[​](https://docs.directadmin.com/changelog/version-1.694.html#file-manager-remove-file-action-hook)

A new hook for filemanager remove file action is added [`file_manager_remove_pre.sh`](https://docs.directadmin.com/developer/hooks/file_manager.html#file-manager-remove-pre-sh).

## File Manager file editor redesign evolution update[​](https://docs.directadmin.com/changelog/version-1.694.html#file-manager-file-editor-redesign)

The File Manager file editor has been redesigned with several key changes:

1.   It is now a separate page instead of an overlay modal.
2.   You can now copy the full file path using a button in the toolbar.
3.   You can now navigate to other directories directly from the editor using the folder tree in the sidebar. On mobile devices, you must first return to the directory view because the floating button for opening the folder tree drawer is disabled while the editor is open.
4.   Editor options and switches have a refreshed, more modern design consistent with other editors. Switches use the primary color for `on` and a muted grey color for `off`. Dropdown selectors kept the same available options.
5.   Removed the `Save File As` option, as it was deemed no longer necessary.

![Image 3: Upgraded file editor](https://docs.directadmin.com/assets/file-editor.BxEnVdo2.png)

## New options.conf items new custombuild[​](https://docs.directadmin.com/changelog/version-1.694.html#new-options-conf-items)

In this release CustomBuild got new options:

| Setting | Options | Default value |
| --- | --- | --- |
| `wpcli` | yes/no | yes |
| `imapsync` | yes/no | yes |
| `composer` | yes/no | _no_* |

*   _one-time autodetection: 'yes' if composer exists and the option is not present in `options.conf`_

## Updated service monitoring page evolution update[​](https://docs.directadmin.com/changelog/version-1.694.html#updated-service-monitoring-page)

The service monitoring page now features a refreshed design, improved mobile experience, and auto-refresh functionality.

![Image 4: New services page desktop](https://docs.directadmin.com/assets/services-after-desktop.CsQp4qNU.png)![Image 5: New services page mobile](https://docs.directadmin.com/assets/services-after-mobile.epcth-nd.png)

## Changes to plugins uploaded with Plugin Manager update[​](https://docs.directadmin.com/changelog/version-1.694.html#changes-to-plugins-uploaded-with-plugin-manager)

`CMD_PLUGIN_MANAGER` "add" action logic was changed. Most notably, it will:

1.   **Always install and activate plugin**. The option for selecting whether to install newly added plugin is removed from Evolution and Enhanced.
2.   Removes plugin if an error is encountered. For example, if plugin was successfully uploaded, but then the installation ("install.sh") script failed, it won't be visible in Plugin Manager page anymore.
3.   Does not allow plugins with same ID. If another plugin with the same ID already exists, user has to remove the existing one first.
4.   "X-DirectAdmin" header is no longer respected.
5.   "URL" type upload uses different "User-Agent" header than before. This change affects servers that look for specific string within this header to permit download.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.694.html#software-version-changes)

*   **composer** updated from `2.9.3` to `2.9.5`
*   **MySQL 8.0** updated from `8.0.44` to `8.0.45`
*   **MySQL 8.4** updated from `8.4.7` to `8.4.8`

## Avoid double email delivery with broken forwarder configuration fix[​](https://docs.directadmin.com/changelog/version-1.694.html#avoid-double-email-delivery-with-broken-forwarder-configuration)

Exim mail server configuration was updated to avoid double delivery of emails to the UNIX user account mailbox when `system_user_to_virtual_passwd` is enabled but the forwarders file `/etc/virtual/{domain}/aliases` still contains legacy forwarding to the system mailbox.

## File Manager checks directory access before navigating evolution fix[​](https://docs.directadmin.com/changelog/version-1.694.html#file-manager-checks-directory-access-before-navigating)

The File Manager now checks whether the target directory is accessible before redirecting the user and updating the path value in the URL.

Previously, in some cases the URL path could become out of sync with the directory that was actually being displayed.

## Cannot edit JSON files in File Manager evolution fix[​](https://docs.directadmin.com/changelog/version-1.694.html#cannot-edit-json-files-in-file-manager)

A recent upgrade to the File Manager file editor content loading request caused valid JSON files to fail to load, showing an empty editor instead.

This issue is fixed in this version.

## Updated systemd socket configuration for isolated PHP-FPM mode fix[​](https://docs.directadmin.com/changelog/version-1.694.html#updated-systemd-socket-configuration-for-isolated-php-fpm-mode)

Old systemd (on RHEL 8 systems) do not properly support working directory management for socket files (the `RuntimeDirectoryPreserve` option). This caused isolated PHP-FPM service reconfiguration to remove other sockets on RHEL 8 systems.

The isolated PHP-FPM socket configuration file is updated to manually manage the working directory lifecycle. This makes it work correctly on all supported Linux distributions.

## Removed tokens from custom menu entries evolution removal[​](https://docs.directadmin.com/changelog/version-1.694.html#removed-tokens-from-custom-menu-entries)

Tokens (`|DOMAIN|`, `|WEBAPPS_SSL|`, `|HOSTNAME|`, `|WEBMAIL_LINK|`) no longer resolve to different values for menu entries added within "Customize Evolution Skin" page.

## Support for the SPF DNS resource record type removal[​](https://docs.directadmin.com/changelog/version-1.694.html#support-for-the-spf-dns-resource-record-type)

The email [Sender Policy Framework](https://datatracker.ietf.org/doc/html/rfc7208) (also known as SPF) uses the DNS TXT record type. The explicit SPF DNS record should [not be used](https://datatracker.ietf.org/doc/html/rfc7208#section-14.1) by the SPF implementations.

Starting with this release, DirectAdmin will no longer support the explicit SPF DNS record type. The configuration option `dns_spf`, which used to enable this functionality, is removed.

## Removed SpamAssassin update frequency setting custombuild removal[​](https://docs.directadmin.com/changelog/version-1.694.html#removed-spamassassin-update-frequency-setting)

The CustomBuild option `sa_update` is removed from the `options.conf` file. This option was used to control how often the script to update SpamAssassin rules is called.

The new rules update file will run once per day by default. The execution frequency and update command can be customised by creating a custom copy of the `configure/spamassassin/sa-update-cron` file.
