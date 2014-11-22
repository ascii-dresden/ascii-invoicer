# ascii invoicer

## introduction


## What is invoicer?

### A brief history
Invoicer is a tool that was initially created to more easily create PDF offers and invoices.

## Usage

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
ascii calendar # Create a calendar from all caterings
ascii csv      # Exports Current year into CSV (uses list)
```

### Miscellaneous 

```bash
ascii path      # Return projects storage path
ascii settings  # View settings
ascii templates # List or add templates
ascii whoami    # Invoke settings --show manager_name
ascii version   # Display version
```

## Filesstructure

* configuration is located in ~/.ascii-invoicer.yml
* the projects directory contains working, archive and templates

## Configuration

## Aliases

* list: -l, l, ls, dir
* display: -d, show
* archive: close
* invoice: -l
* offer: -o
* settings: config
* log: history

