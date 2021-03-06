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
	EDIT: we are <del>now using</del> <ins>considering</ins> java because we found a [gedcom5 to gedcomx converter](https://github.com/FamilySearch/gedcom5-conversion) in that language.  We are also considering using a [java web socket server](https://github.com/TooTallNate/Java-WebSocket) because none of us have spun up a java web server and been happy with the result.
- use the FS gedcomx SDK
- use someone else's gedcom parser if we can find one
- If we use the gedcom5 to gedcomx converter linked above, we need to ensure it works correctly. Initial testing is not promissing because it appears to depend on a project that has moved/been removed.

## TODO:

- contact Dallan Quass to see what happened to the gedcom parser he used to host at https://github.com/DallanQ/gedcom 
	- resolved; project moved to [https://github.com/FamilySearch/gedcom](https://github.com/FamilySearch/gedcom)


# Open questions

- what DB (and what schema?)
	- option: we convert to java objects and dump to [orientdb](http://orientdb.com/docs/last/Object-Database.html)
	- option: we recreate the gedcom-x schema in RDB tables
	- option: we store gedcom-x JSON in MongoDB
- who hosts it
- does each submission get its own URL or its own ID within a single "tree"?
	- or a URL per user?
	- the authentication will probably inform this decision.

# Delayed for future

- add oath2
- add a front-end using open-source tree visualization built on top of the REST
