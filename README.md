# ascii invoicer

## introduction

The ascii-invoicer is a command-line tool that manages projects and stores them not in a database but in a folder structure. New projects can be created from templates and are stored in a working directory. Projects can be archived, each year will have its own archive. A project consists of a folder containing a yaml file describing it and a number of attached files, such tex files. Projects can contain products and personal. You can create preliminary offers and invoices from your projects.

## Usage

Each of these sections starts with a list of commands.
Read the help to each command with `ascii help [COMMAND]` to find out about all parameters, especially *list* has quite a few of them.

### Get started with

```bash
ascii help [COMMAND]                # Describe available commands or one specific command
ascii list                          # List current Projects
ascii display NAMES                 # Shows information about a project in different ways
```

### Project Life-Cycle

```bash
ascii new NAME                      # Creating a new project
ascii edit NAMES                    # Edit project
ascii offer NAMES                   # Create an offer from project
ascii invoice NAMES                 # Create an invoice from project
ascii archive NAME                  # Move project to archive
ascii reopen YEAR NAME              # reopen an archived project
```

### GIT Features

```bash
ascii add NAMES
ascii commit -m, --message=MESSAGE
ascii log
ascii pull
ascii push
ascii status
```

These commands behave similar to the original git commands.
The only difference is that you select projects just like you do with other ascii commands (see edit, display, offer, invoice).
Commit uses -m (like in git) but unlike git does not (yet) open an editor if you leave out the message.

#### CAREFUL:
These commands are meant as a convenience, they ARE NOT however a *complete* replacement for git!
You should always pull before you start working and push right after you are done in order to avoid merge conflicts.
If you do run into such problems go to storage directory `cd $(ascii path)` and resolve them using git.

Personal advice N°1: use `git pull --rebase`

Personal advice N°2: add this to your .bash_aliases:
`alias agit="git --git-dir=$(ascii path)/.git --work-tree=$(ascii path)"`

### Exporting

```bash
ascii calendar # Create a calendar file from all caterings named "invoicer.ics"
ascii csv      # Prints a CSV list of current year into CSV
```
You can pipe the csv into column (`ascii csv | column -ts\;`) to display the table in you terminal.

### Miscellaneous 

```bash
ascii path      # Return projects storage path
ascii settings  # View settings
ascii templates # List or add templates
ascii whoami    # Invoke settings --show manager_name
ascii version   # Display version
```

## Filesstructure

Your config-file is located in ~/.ascii-invoicer.yml but you can also access it using `ascii settings --edit` or even `ascii edit --settings`.
The projects directory contains working, archive and templates. If you start with a blank slate you might want to put the tepm

## Aliases

* list: -l, l, ls, dir
* display: -d, show
* archive: close
* invoice: -l
* offer: -o
* settings: config
* log: history

## Known Issues

Some strings may cause problems when rendering latex, e.g.
a client called `"ABC GmbH & Co. KG"`.
The `"&"` causes latex to fail, `\&"` bugs the yaml parser but `"\\&"` will do the trick.

## Pro tips

Check out `repl ascii`.
You should copy [repl-file](src/repl/ascii) into ~/.repl/ascii and install rlwrap to take advantage of all the repl goodness such as autocompletion and history.

# Building

```bash
# lets install building dependencies
cd src
gem install bundler # if you don't already have it
bundle install # pulls all building dependencies
# actually now you're done

# after you made your own changes
rake install # installs the gem
rake gem # builds the gem

# that's it
```

## Dependencies

* rvm works best, otherwise I have not tested installing it anywhere else
* a lot of latex packages to run the offer/invoice export
