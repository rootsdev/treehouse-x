# Introduction

This was one of the hackathon projects in RootsTech 2016.
As such, it will probably make little progress at first and then be forgotten.

## User Story

User goes to website and submits a `.ged` file.
The submit-server converts (as much of that as possible) to gedcom-x and stores it in a DB.

A (separate?) server serves the file using the gedcom-x RS specification.

# Decisions

- C# (because the majority of the people at this table at least know of that language)
- use the FS gedcomx API
- use someone else's gedcom parser if we can find one

# Open questions

- what DB
- who hosts it
- do we need to use oath2
- does each submission get its own URL or its own ID within a single "tree"?
