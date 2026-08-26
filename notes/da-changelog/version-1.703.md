Title: Version 1.703 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.703.html

Markdown Content:
Released: 2026-06-??

*   [Support for Ubuntu 26.04 LTS new](https://docs.directadmin.com/changelog/version-1.703.html#support-for-ubuntu-26-04-lts)
*   [‼️ More secure outgoing email delivery new](https://docs.directadmin.com/changelog/version-1.703.html#%EF%B8%8F-more-secure-outgoing-email-delivery)
*   [New directadmin.conf fields new](https://docs.directadmin.com/changelog/version-1.703.html#new-directadmin-conf-fields)
*   [Domain pointers in search results evolution new](https://docs.directadmin.com/changelog/version-1.703.html#domain-pointers-in-search-results)
*   [Flexible Exim configuration for not counting local-to-local emails update](https://docs.directadmin.com/changelog/version-1.703.html#flexible-exim-configuration-for-not-counting-local-to-local-emails)
*   [IMAPSync import and export page alerts evolution update](https://docs.directadmin.com/changelog/version-1.703.html#imapsync-import-and-export-page-alerts)
*   [IMAPSync "Start migration" button loading state evolution update](https://docs.directadmin.com/changelog/version-1.703.html#imapsync-start-migration-button-loading-state)
*   [Update admin_ssl_replace_all_expired_invalid in directadmin.conf update](https://docs.directadmin.com/changelog/version-1.703.html#update-admin-ssl-replace-all-expired-invalid-in-directadmin-conf)
*   [API Documentation textarea color in dark mode evolution fix](https://docs.directadmin.com/changelog/version-1.703.html#api-documentation-textarea-color-in-dark-mode)
*   [Close Nginx Unit edit route dialog on submit evolution fix](https://docs.directadmin.com/changelog/version-1.703.html#close-nginx-unit-edit-route-dialog-on-submit)
*   [IMAPSync validation evolution fix](https://docs.directadmin.com/changelog/version-1.703.html#imapsync-validation)
*   [Unicode characters in search fix](https://docs.directadmin.com/changelog/version-1.703.html#unicode-characters-in-search)
*   [Unicode characters in FTP management page fix](https://docs.directadmin.com/changelog/version-1.703.html#unicode-characters-in-ftp-management-page)
*   [Removed "Custom Error Pages" page evolution removal](https://docs.directadmin.com/changelog/version-1.703.html#removed-custom-error-pages-page)
*   [Dropped /docs/swagger.json removal](https://docs.directadmin.com/changelog/version-1.703.html#dropped-docs-swagger-json)
*   [Dropped move_user_to_reseller.sh usage removal](https://docs.directadmin.com/changelog/version-1.703.html#dropped-move-user-to-reseller-sh-usage)
*   [Removed directadmin.conf fields removal](https://docs.directadmin.com/changelog/version-1.703.html#removed-directadmin-conf-fields)

## Support for Ubuntu 26.04 LTS new[​](https://docs.directadmin.com/changelog/version-1.703.html#support-for-ubuntu-26-04-lts)

This release of DirectAdmin starts supporting the latest Ubuntu 26.04 LTS systems.

## ‼️ More secure outgoing email delivery new[​](https://docs.directadmin.com/changelog/version-1.703.html#%EF%B8%8F-more-secure-outgoing-email-delivery)

The Exim configuration is updated to use a more secure email delivery mode for outgoing emails. When outgoing email is being routed, Exim will check the MX records for the destination domain even if this domain is configured as local on the server. If MX records point back to the server, the local mail delivery will be performed. If MX records point to an external server, then email will be delivered over SMTP.

Key benefits of this change:

*   Protection from email hijacking. If some user adds a popular domain like `gmail.com` or `proton.me` as his own domain, he will not be able to hijack outgoing emails for these domains that are being sent by other users on the same server.
*   Correct routing when MX proxy is being used. If the domain owner is using an external mail filtering service, his domain MX records will point to the service provider. After email is checked by the service provider it will be delivered to the DirectAdmin server. Emails from one user on the server to another user on the same server would get routed to the external service provider.

This new feature is controlled with the `FORCED_MX_DNS_CHECK` macro. It is enabled by default but can be disabled by setting this macro to the value `no`.

Examples:

sh

```
# Disable strict MX checking (insecure):
sed -i '/^FORCED_MX_DNS_CHECK /d' /etc/exim.variables.conf.custom
echo 'FORCED_MX_DNS_CHECK = no' >> /etc/exim.variables.conf.custom
da build exim_conf

# Restore strict MX checking
sed -i '/^FORCED_MX_DNS_CHECK /d' /etc/exim.variables.conf.custom
da build exim_conf
```

## New `directadmin.conf` fields new[​](https://docs.directadmin.com/changelog/version-1.703.html#new-directadmin-conf-fields)

The following new fields have been added to `directadmin.conf`:

*   [`acme_disable_after_failures`](https://docs.directadmin.com/directadmin/general-usage/all-directadmin-conf-values.html#acme-disable-after-failures) - Controls how many times to retry TLS certificate issuance/renewal before disabling it. Zero value means retry indefinitely. 
> Deprecates `letsencrypt_disable_renew_after_renew_failure`&`letsencrypt_renewal_failure_notice_after_attempt`

*   [`notify_admins_on_user_acme_failures`](https://docs.directadmin.com/directadmin/general-usage/all-directadmin-conf-values.html#notify-admins-on-user-acme-failures) - Notify the admins when user's TLS certificate fails to issue or renew. 
> Deprecates `letsencrypt_renewal_notice_to_admins`

*   [`notify_reseller_on_user_acme_failures`](https://docs.directadmin.com/directadmin/general-usage/all-directadmin-conf-values.html#notify-reseller-on-user-acme-failures) - Notify the reseller when user's TLS certificate fails to issue or renew. 
> Deprecates `letsencrypt_renewal_notice_to_admins`

## Domain pointers in search results evolution new[​](https://docs.directadmin.com/changelog/version-1.703.html#domain-pointers-in-search-results)

Search results now return domain pointers.

## Flexible Exim configuration for not counting local-to-local emails update[​](https://docs.directadmin.com/changelog/version-1.703.html#flexible-exim-configuration-for-not-counting-local-to-local-emails)

Starting with DirectAdmin [version 1.702](https://docs.directadmin.com/changelog/version-1.702.html#sent-email-limits-will-count-local-to-local-emails), the Exim mail server configuration is updated to count all emails (including emails delivered locally) into the email send limit.

This release adds a new Exim configuration macro `SEND_LIMIT_COUNT_RECIPIENTS`, that allows selecting which recipients are counted in the email send limit and which are not. This option allows restoring the old Exim behaviour of not counting emails that will be delivered to the same server.

Default macro definition is `SEND_LIMIT_COUNT_RECIPIENTS = $recipients_list`. This means all recipients must be counted. Examples for different behaviour:

sh

```
# Do not count emails where sender and recipient address is from the same
# domain:
sed -i '/^SEND_LIMIT_COUNT_RECIPIENTS /d' /etc/exim.variables.conf.custom
echo 'SEND_LIMIT_COUNT_RECIPIENTS = ${filter{$recipients_list}{ !eq{${domain:$item}}{$sender_address_domain} }}' >> /etc/exim.variables.conf.custom
da build exim_conf

# Backwards compatibility mode, do not count mails that will be delivered
# locally:
sed -i '/^SEND_LIMIT_COUNT_RECIPIENTS /d' /etc/exim.variables.conf.custom
echo 'SEND_LIMIT_COUNT_RECIPIENTS = ${filter{$recipients_list}{ !match_domain{${domain:$item}}{+local_domains} }}' >> /etc/exim.variables.conf.custom
da build exim_conf
```

## IMAPSync import and export page alerts evolution update[​](https://docs.directadmin.com/changelog/version-1.703.html#imapsync-import-and-export-page-alerts)

Previously, errors were shown as toast notifications which disappeared after a few seconds. After this update, errors will be shown within the page until user dismisses the error.

After a successful migration, users will be redirected to IMAPSync migrations page without a success toast notification.

## IMAPSync "Start migration" button loading state evolution update[​](https://docs.directadmin.com/changelog/version-1.703.html#imapsync-start-migration-button-loading-state)

The "Start migration" button within IMAPSync import and export pages now gets disabled and shows a spinner when a request is already a progress.

## Update `admin_ssl_replace_all_expired_invalid` in `directadmin.conf`update[​](https://docs.directadmin.com/changelog/version-1.703.html#update-admin-ssl-replace-all-expired-invalid-in-directadmin-conf)

Drop value `2` for [`admin_ssl_replace_all_expired_invalid`](https://docs.directadmin.com/directadmin/general-usage/all-directadmin-conf-values.html#admin-ssl-replace-all-expired-invalid) as it is unused.

It may be either enabled or disabled.

## API Documentation textarea color in dark mode evolution fix[​](https://docs.directadmin.com/changelog/version-1.703.html#api-documentation-textarea-color-in-dark-mode)

Within the "API Documentation" page, when trying out a POST/PATCH/PUT API request, the text inside apparent textarea was indistinguishable from the background.

## Close Nginx Unit edit route dialog on submit evolution fix[​](https://docs.directadmin.com/changelog/version-1.703.html#close-nginx-unit-edit-route-dialog-on-submit)

When editing a route in Nginx Unit, clicking "Save" now automatically closes the dialog.

## IMAPSync validation evolution fix[​](https://docs.directadmin.com/changelog/version-1.703.html#imapsync-validation)

Fixed the following problems with validation in IMAPSync import and export pages:

*   pressing enter while focusing an input used to bypass input validation.
*   "User" input field was not validated

## Unicode characters in search fix[​](https://docs.directadmin.com/changelog/version-1.703.html#unicode-characters-in-search)

Response for `GET /api/search/resources` now supports unicode characters.

## Unicode characters in FTP management page fix[​](https://docs.directadmin.com/changelog/version-1.703.html#unicode-characters-in-ftp-management-page)

FTP management page was updated to display unicode characters within table's "account" column.

## Removed "Custom Error Pages" page evolution removal[​](https://docs.directadmin.com/changelog/version-1.703.html#removed-custom-error-pages-page)

The "Custom Error Pages" page (found in user level, under the "Advanced Features" category) was removed.

## Dropped /docs/swagger.json removal[​](https://docs.directadmin.com/changelog/version-1.703.html#dropped-docs-swagger-json)

`/docs/swagger.json` redirect to `/static/swagger.json` was removed.

## Dropped move_user_to_reseller.sh usage removal[​](https://docs.directadmin.com/changelog/version-1.703.html#dropped-move-user-to-reseller-sh-usage)

The `CMD_MOVE_USERS` endpoint no longer uses the `move_user_to_reseller.sh` and `custom/move_user_to_reseller.sh` scripts.

Any custom user transfer logic in `custom/move_user_to_reseller.sh` will need to be moved to [`move_user_to_reseller_(pre|post)`](https://docs.directadmin.com/developer/hooks/user_reseller_management.html#move-user-to-reseller-pre-sh-move-user-to-reseller-post-sh) hooks.

The "move_user_to_reseller.sh" script has been updated to use the "POST /api/change-user-creator" endpoint.

## Removed `directadmin.conf` fields removal[​](https://docs.directadmin.com/changelog/version-1.703.html#removed-directadmin-conf-fields)

The following fields have been removed from `directadmin.conf`:

*   `letsencrypt_disable_renew_after_renew_failure` - superseded by [`acme_disable_after_failures`](https://docs.directadmin.com/directadmin/general-usage/all-directadmin-conf-values.html#acme-disable-after-failures)
*   `letsencrypt_renewal_failure_notice_after_attempt` - superseded by [`acme_disable_after_failures`](https://docs.directadmin.com/directadmin/general-usage/all-directadmin-conf-values.html#acme-disable-after-failures)
*   `letsencrypt_renewal_notice_to_admins` - superseded by [`notify_admins_on_user_acme_failures`](https://docs.directadmin.com/directadmin/general-usage/all-directadmin-conf-values.html#notify-admins-on-user-acme-failures)&[`notify_reseller_on_user_acme_failures`](https://docs.directadmin.com/directadmin/general-usage/all-directadmin-conf-values.html#notify-reseller-on-user-acme-failures)
