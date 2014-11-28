
2.5.1 / 2014-11-28
==================

 * fixed: won't create calendar file if not all events are valid
 * changed: invoice_date needs to be hard coded before archiving is allowed

2.5.0 / 2014-11-27
==================
## new features since 2.4.x

 * added: a bunch of aliases for commands: [log => history, show => display, etc]
 * added: management of template files ( luigi 1.1.0 )
    * `ascii new --template NAME`
    * `ascii path -t` for templates path
    * `ascii edit -t NAME`
    * `ascii templates --add` to add changes to templates to staging
 * added: displaying if payed in verbose listing ( fixes #5 )
 * added: "canceled" to csv and list
 * added: "final" to csv and list
 * added: individual taxes per producttaxes
 * added: logging errors to file (~/.ascii_log)
 * added: supporting different taxes in one document (e.g. 19% and 7%)
 * added: repl! Check out "repl ascii"!

 * changed: output of `ascii display`
 * changed: calendar now writes into a file
 * changed: calendar creation is now part of filtering -> errors show up in list
 * changed: writing calendar right into invoicer.ics

## under the hood
 * made it all installable a lot easier trough rubygems
    * euro
    * luigi
    * hash-graft
    * textboxes

 * cut out a lot of the code and put it into extra gems
 * documented usage in [README](README.md)
 * cleaned up a lot of old stuff
 * removed a bunch of outdated tests
 * changed: moved branding into settings, out of code
 * changed: moved settings management into its own class
 * changed: list --paths no longer needs to parse projects, works even when projects are broken
 * fixed: rescuing yaml Syntax Error ruby 1.9 and 2.1 style
 * fixed: ascii commit -m was expecting a numeric value ( stupid )
 * fixed: avoiding latex build to fail in case a project name contains a "_"
 * fixed: not creating latex if output path does not exist
 * lots more around the edges



