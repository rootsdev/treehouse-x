# Introduction

This was one of the hackathon projects in RootsTech 2016.
As such, it will probably make little progress at first and then be forgotten.

## User Story

User goes to website and submits a `.ged` file.
The submit-server converts (as much of that as possible) to gedcom-x and stores it in a DB.

A (separate?) server serves the file using the gedcom-x RS specification.

# Decisions

-   C# (because the majority of the people at this table at least know of that language)
	EDIT: people left the table.  Now we are in Python!
	EDIT: we were just told php has a built in server; we are now 1/3 done!
	EDIT: we are --now using--considering java because we found a [gedcom5 to gedcomx converter](https://github.com/FamilySearch/gedcom5-conversion) in that language.  We are also considering using a [java web socket server](https://github.com/TooTallNate/Java-WebSocket) because none of us have spun up a java web server and been happy with the result. 
- use the FS gedcomx SDK
- use someone else's gedcom parser if we can find one

# Open questions

- what DB
- who hosts it
- does each submission get its own URL or its own ID within a single "tree"?

# Delayed for future

- add oath2
- add a front-end using open-source tree visualization built on top of the REST
