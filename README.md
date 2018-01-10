Work in progress
----------------
### Non-exhaustive todo list
* re: check 008 does not have 40 byte positions
  does our sql query capture this? in Sierra postgres, is an 008 of just "a" possible, or is it getting stored as "a                 [etc]". see comment in HathiRecord.check_marc
* any tests/testing
* check that all checks from the ht_bib_compiler.pl are included
* make sure oclcnum logic is working.
* anything SierraBib still needs

Installation
------------
This is dependent on this postgres_connect repo BUT see note below:
* https://github.com/ldss-jm/postgres_connect.

NOTE: While postgres_connect is being reworked to add Sierra bib record knowledge/functionality, this repo is dependent on this specific branch of postgres_connect:
* https://github.com/ldss-jm/postgres_connect/tree/sierra-postgres-utilities

Basic usage
-----------

- Install this in some working directory
- Also install the branch of postgres_connect
  - install that into "sierra_postgres_utilities"
  - "sierra_postgres_utilities" and the working directory (i.e. this hathi ingest repo) need to have the same parent directory
- Place input files in working directory
- Run main.rb

Input files
-----------

### search.csv -- not included here
is a search results file from Internet Archive for items we're interested in. Both queries below extend back for all time, practically, so adjust the publicdate if you want to look only at items more recently ingested into IA.

This query does not exclude ncdhc items:

https://archive.org/advancedsearch.php?q=scanningcenter%3A(chapelhill)+AND+unc_bib_record_id%3A%5B*+TO+*%5D+AND+publicdate%3A%5B2001-01-03+TO+null&fl%5B%5D=unc_bib_record_id,identifier,identifier-ark,volume,publicdate,sponsor,contributor,collection&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=5000000&page=1&output=csv&callback=callback&save=yes


This query excludes ncdhc items:

https://archive.org/advancedsearch.php?q=scanningcenter%3A(chapelhill)+AND+unc_bib_record_id%3A%5B*+TO+*%5D+AND+publicdate%3A%5B2001-01-03+TO+null%5D+AND+NOT+collection%3A(ncdhc)&fl%5B%5D=unc_bib_record_id,identifier,identifier-ark,volume,publicdate,sponsor,contributor,collection&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=5000000&page=1&output=csv&callback=callback&save=yes


### nc01.arks.txt -- mid-2017 file included for convenience
is a list of ark ids for all unc-contributed items in HathiTrust as of mid-2017 (which remains current as of Jan 1 2018). It should be updated (i.e. kept current) if you want automated detection of whether a UNC record already exists in HT for an IA item.


Output
------
ia_log.csv -- log of all IA records with their status (one of: 'no sierra record', 'no IA ark_id found', 'record already in HT', 'failed MARC checks', 'wrote xml')

bib_errors.txt -- txt file of bibs with errors

hathi_marcxml.xml -- marcxml for bibs without errors to give to HT
