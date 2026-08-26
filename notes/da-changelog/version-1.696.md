Title: Version 1.696 | DirectAdmin Docs

URL Source: https://docs.directadmin.com/changelog/version-1.696.html

Markdown Content:
Released: 2026-03-03

*   [Show hidden files in File Manager evolution new](https://docs.directadmin.com/changelog/version-1.696.html#show-hidden-files-in-file-manager)
*   [Domain availability check before issuing the wildcard certificate new](https://docs.directadmin.com/changelog/version-1.696.html#domain-availability-check-before-issuing-the-wildcard-certificate)
*   [Mobile table pagination now matches desktop layout evolution update](https://docs.directadmin.com/changelog/version-1.696.html#mobile-table-pagination-now-matches-desktop-layout)
*   [File editors read-only mode improvements evolution update](https://docs.directadmin.com/changelog/version-1.696.html#file-editors-read-only-mode-improvements)
*   [Improved accessibility in File Manager evolution update](https://docs.directadmin.com/changelog/version-1.696.html#improved-accessibility-in-file-manager)
*   [Improved navigation between user and reseller data pages evolution update](https://docs.directadmin.com/changelog/version-1.696.html#improved-navigation-between-user-and-reseller-data-pages)
*   [Refactored Apache modules install custombuild update](https://docs.directadmin.com/changelog/version-1.696.html#refactored-apache-modules-install)
*   [Software version changes custombuild update](https://docs.directadmin.com/changelog/version-1.696.html#software-version-changes)
*   [Suggest sending a notification on manual user suspension update](https://docs.directadmin.com/changelog/version-1.696.html#suggest-sending-a-notification-on-manual-user-suspension)
*   [Email template for system messages will show the message contents update](https://docs.directadmin.com/changelog/version-1.696.html#email-template-for-system-messages-will-show-the-message-contents)
*   [Certificates preliminary check for HTTP challenge update](https://docs.directadmin.com/changelog/version-1.696.html#certificates-preliminary-check-for-http-challenge)
*   [Mailbox last login time tracking fix](https://docs.directadmin.com/changelog/version-1.696.html#mailbox-last-login-time-tracking)
*   [Domain quota and bandwidth validation fix](https://docs.directadmin.com/changelog/version-1.696.html#domain-quota-and-bandwidth-validation)
*   [Allow decimal numbers in resource limits evolution fix](https://docs.directadmin.com/changelog/version-1.696.html#allow-decimal-numbers-in-resource-limits)
*   [A single user suspension template for different target user access levels removal](https://docs.directadmin.com/changelog/version-1.696.html#a-single-user-suspension-template-for-different-target-user-access-levels)
*   [Removed apache_public_html configuration option from directadmin.conf removal](https://docs.directadmin.com/changelog/version-1.696.html#removed-apache-public-html-configuration-option-from-directadmin-conf)
*   [Removed notify_creator_on_suspend configuration option from directadmin.conf removal](https://docs.directadmin.com/changelog/version-1.696.html#removed-notify-creator-on-suspend-configuration-option-from-directadmin-conf)

File Manager now includes an option to show or hide hidden files and directories (items with names starting with `.`), similar to other common file management applications.

This toggle is applied consistently across the directory list, folder tree, search results, and path selector.

When hidden files are disabled, dot-prefixed entries are filtered out from these views to keep navigation cleaner.

This option can be found in _"Skin Options > File Manager > Show hidden files and folders"_. By default it is toggled.

## Domain availability check before issuing the wildcard certificate new[​](https://docs.directadmin.com/changelog/version-1.696.html#domain-availability-check-before-issuing-the-wildcard-certificate)

A new check that covers obvious DNS zone misconfigurations will be performed before issuing a wildcard certificate. The purpose of this check is to terminate attempts to issue a certificate for invalid or not properly delegated domains without contacting ACME provider servers. This reduces the chances for the server to hit ACME provider rate limits.

Before trying to issue a wildcard certificate for a domain, the NS records for this domain will be looked up using the default DNS resolver and using the local bind service. On properly configured servers the results of these two lookups will be the same.

On correctly configured servers, the domain NS records on the local DNS service and publicly available DNS records will match. For domains that can not be managed on this server, the results will return different NS server names.

The preliminary domain availability test will be considered successful if the two lookups share at least one common NS server name.

**Note**: This check will NOT be performed if:

*   A custom DNS provider is configured for this domain.
*   There is an `_acme_challenge` CNAME type record added for this domain.

## Mobile table pagination now matches desktop layout evolution update[​](https://docs.directadmin.com/changelog/version-1.696.html#mobile-table-pagination-now-matches-desktop-layout)

The mobile table pagination controls were updated to match the desktop experience and keep the interface consistent across layouts.

The previous mobile popover-based selector was replaced with the same dropdown component used on desktop.

The control order was also aligned: navigation buttons now appear on the left and the rows-per-page selector on the right, just like in some of desktop tables.

## File editors read-only mode improvements evolution update[​](https://docs.directadmin.com/changelog/version-1.696.html#file-editors-read-only-mode-improvements)

Read-only mode in file editors was improved to behave more naturally. This mode is only applied when file content is being loaded or saved to prevent modifications during requests.

Users can now select and copy text while editing remains disabled. Previously, text selection and copying were blocked when read-only mode was enabled.

## Improved accessibility in File Manager evolution update[​](https://docs.directadmin.com/changelog/version-1.696.html#improved-accessibility-in-file-manager)

Accessibility support was improved in several File Manager components, including the file editor header toolbar, file editor footer toolbar, and the toolbar for actions on selected files and folders.

These updates make those controls easier to use with keyboard navigation and assistive technologies, improving overall usability and consistency.

## Improved navigation between user and reseller data pages evolution update[​](https://docs.directadmin.com/changelog/version-1.696.html#improved-navigation-between-user-and-reseller-data-pages)

Replaced tab-based navigation with explicit and more usual button navigation in page actions for clearer, more intuitive access to each page.

## Refactored Apache modules install custombuild update[​](https://docs.directadmin.com/changelog/version-1.696.html#refactored-apache-modules-install)

Slight changes in configuration when installing `mod_lsapi`, `mod_hostinglimits` and `mod_modproctitle` Apache modules:

*   Static `IncludeOptional` in `httpd.conf` are used to include the modules (old way was manipulating the lines in `httpd-includes.conf` file)
*   The existence of the files in `config/extra/` denotes if the module is enabled or not. RewriteConfs takes care of this.

## Software version changes custombuild update[​](https://docs.directadmin.com/changelog/version-1.696.html#software-version-changes)

*   **MariaDB 12.3** added with `12.3.1` version
*   **litespeed** updated from `6.3.4-10` to `6.3.4-11`
*   **ModSecurity** rules from **OWASP CRS** updated from `4.23.0` to `4.24.0`
*   **xapian-core** updated from `1.4.30` to `1.4.31`

## Suggest sending a notification on manual user suspension update[​](https://docs.directadmin.com/changelog/version-1.696.html#suggest-sending-a-notification-on-manual-user-suspension)

When the user account is being manually suspended by an administrator or reseller, an option to send a notification for suspended users will always be visible and enabled by default.

This makes suspension notifications work similarly to the new user create notifications. It suggests notifying the user but allows notification to be omitted at the time when suspension action is being performed.

Before this release, notifications were not being sent by default. It was possible to enable automatic notifications by customising the notification message.

Suspension actions via API calls will not send notifications unless the `notify=yes` parameter is passed in the request.

## Email template for system messages will show the message contents update[​](https://docs.directadmin.com/changelog/version-1.696.html#email-template-for-system-messages-will-show-the-message-contents)

The templates for email notifications about new messages in the DirectAdmin message center are updated to include the full message content in the email.

Before this update, only the message subject was visible in the email. To check the full message, the user would have to access the DirectAdmin UI.

The updated template allows users to read the whole message without accessing the DirectAdmin interface.

The following templates are updated:

*   `data/templates/message_user.txt` - an email template for system messages. It will include the message body and will have a static suffix with a link to preview the message in the DirectAdmin interface.
*   `data/templates/message_tech.txt` - an email template for a new ticket. It will have full message contents and a link to preview the ticket in the DirectAdmin interface.
*   `templates/message_footer.txt` will be empty by default.

## Certificates preliminary check for HTTP challenge update[​](https://docs.directadmin.com/changelog/version-1.696.html#certificates-preliminary-check-for-http-challenge)

SSL certificates issueing preliminary check for HTTP challenge is updated to work in cases when web server (such as apache or nginx) is not running.

## Mailbox last login time tracking fix[​](https://docs.directadmin.com/changelog/version-1.696.html#mailbox-last-login-time-tracking)

Dovecot email service has updated the log lines marking a successful client login. This change prevented DirectAdmin from correctly tracking the last successful mailbox access times.

The log patterns are updated to support old and new Dovecot versions.

## Domain quota and bandwidth validation fix[​](https://docs.directadmin.com/changelog/version-1.696.html#domain-quota-and-bandwidth-validation)

The modify domain page is updated to validate bandwidth and quota limit values more strictly. It will no longer allow entering too long sequences of digits.

## Allow decimal numbers in resource limits evolution fix[​](https://docs.directadmin.com/changelog/version-1.696.html#allow-decimal-numbers-in-resource-limits)

Input validation will no longer fail if using decimal numbers for user resource limit inputs:

*   IO Read Bandwidth Max
*   IOPS Read Max
*   IO Write Bandwidth Max
*   IOPS Write Max
*   Memory High
*   Memory Max

## A single user suspension template for different target user access levels removal[​](https://docs.directadmin.com/changelog/version-1.696.html#a-single-user-suspension-template-for-different-target-user-access-levels)

There will be a single template for the message that gets sent to the suspended users instead of having different templates for suspending administrators, suspending resellers, or suspending normal users.

Every reseller or admin can still have a customised suspension message, but this message will be used when suspending any user account.

For administrator accounts that used to have all three templates customised, the template for reseller level (file `./data/users/{name}/r_suspension.json`) and the template for admin level (file `./data/users/{name}/a_suspension.json`) will be removed. The template for normal users (file `./data/users/{user}/u_suspension.json`) will continue to be used.

## Removed `apache_public_html` configuration option from `directadmin.conf`removal[​](https://docs.directadmin.com/changelog/version-1.696.html#removed-apache-public-html-configuration-option-from-directadmin-conf)

This option used to allow making the website document root directory to be owned by the `apache` UNIX user. It is deprecated since the introduction of secure access group. The website document root directory will always be owned by the UNIX user that owns the website domain.

## Removed `notify_creator_on_suspend` configuration option from `directadmin.conf`removal[​](https://docs.directadmin.com/changelog/version-1.696.html#removed-notify-creator-on-suspend-configuration-option-from-directadmin-conf)

The option `notify_creator_on_suspend` was used to control if the creator of a suspended user should unconditionally get a message about his user being manually suspended.

Keeping his option enabled was useful when the administrator suspended an account that belongs to some other reseller. In this scenario the real owner of the user gets notified about his user being suspended. However, it also caused useless notifications when the suspension action was being performed by the real user creator. Then he would get a notification about an action he himself has performed.

Keeping this option disabled inverted the situation. It used to make it convenient for the cases when the reseller suspends his own user (no surplus notifications). However, it was not so good when the administrator suspended the user he does not own (the real user owner is not aware of the suspension).

The new behaviour is to pick the best action for both scenarios without having to configure anything.

*   The notification about the user being suspended will not be sent out to his owner if the suspension action is being performed by the user owner himself.
*   The notification will be sent out if the administrator account suspends a user that does not belong to him.
