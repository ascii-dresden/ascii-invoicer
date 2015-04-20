2.5.10 / 2015-04-20
==================

  * changed: replace Euro with Money
  * added: ascii ls --wages updated: paint

2.5.9 / 2015-04-01
==================

  * fixed: "ascii list --final"

2.5.8 / 2015-04-01
==================

  * changed: requirements for building a calendar

2.5.7 / 2015-02-19
==================

  * changed: more verbose caterers display in "ascii list"

2.5.6 / 2015-02-19
==================

  * changed: pointing to log file for parser errors
  * added: "ascii open" to open output pdfs directly if they exist
  * added: highlighting existing output files

2.5.5 / 2015-01-23
==================

  * added: "ascii csv --year" and "ascii output", which equals "ascii path --output"
  * added: event/age
  * added: invoice/delay telling you how long it took to create an invoice
  * added: sorting can now be set in ~/.ascii-invoicer.yml
  * changed: default sort order is now :index
  * fixed: requiring only last_name, not full name for minimal
  * fixed: sorting by index still sorts correctly by date tooo

2.5.4 / 2014-12-19
==================
 * spelling fix in default settings (German, such a complicated language)

2.5.3 / 2014-12-18
==================

  * changed: client name is now required, invoice_date must be set manually
  * fixed: ascii add lacked the --archive option
  * changed: caterers that worked 0h are no longer listed
  * started: $ascii search, works remarkably well for 8 lines of code
  * fixed: correctly refusing to produce invoice if invalid

2.5.2 / 2014-12-03
==================

 * added: "ascii add --template" - though I had that in 2.5.0
 * documented new features
 * added: validating client_fullname
 * added: "list --details" and removed "list --final"
 * introduced "paydelay", meaning how long it took for a catering to be payed
 * changed: --blockers now displays archiving blockers ( more strict )
 * simplified: validation
 * changed: not showing service in "ascii show" there has been none
 * added: filestructure example to readme
 * prettier readme
 * added: show --csv ( check out the README )
 * updated readme
 * added: ascii display does not display errors by default, use -e for that
 * added a note on how to "build" it

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



