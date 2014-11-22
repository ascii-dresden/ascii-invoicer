# ascii invoicer

## introduction


## What is invoicer?

### A brief history
Invoicer is a tool that was initially created to more easily create PDF offers and invoices.

## Usage

    ascii help [COMMAND]                # Describe available commands or one specific command

### Project Life-Cycle

    ascii new NAME                      # Creating a new project
    ascii edit NAMES                    # Edit project
    ascii offer NAMES                   # Create an offer from project
    ascii invoice NAMES                 # Create an invoice from project
    ascii archive NAME                  # Move project to archive
    ascii reopen YEAR NAME              # reopen an archived project

### GIT Features

    ascii add NAMES                     # Git Integration
    ascii commit -m, --message=MESSAGE  # Git Integration
    ascii log                           # Git Integration
    ascii pull                          # Git Integration
    ascii push                          # Git Integration
    ascii status                        # Git Integration

### Exporting

    ascii calendar                      # Create a calendar from all caterings
    ascii csv                           # Equal to: ascii list --all --csv --sort=index --filter event/date:2014

### Convenience

    ascii list                          # List current Projects
    ascii display NAMES                 # Shows information about a project in different ways

### Miscellaneous 
    ascii path                          # Return projects storage path
    ascii settings                      # View settings
    ascii templates                     # List or add templates
    ascii whoami                        # Invoke settings --show manager_name
    ascii version                       # Display version

## Filesstructure

* configuration is located in ~/.ascii-invoicer.yml
* the projects directory contains working, archive and templates
