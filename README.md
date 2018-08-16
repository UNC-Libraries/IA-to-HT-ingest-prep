Work in progress
================
### Non-exhaustive todo list
* remove temporary spandr/IOLC exclusions from split_problems when items fixed
* any tests/testing

Installation
============
- Clone this repo in some working directory
- Clone the sierra-postgres-utilities repo into the same parent directory as this repo
  - https://github.com/UNC-Libraries/sierra-postgres-utilities

IA-to-HT ingest
===============
Overview
-----------
- check_IA_data.rb - checks for IA metadata problems to be resolved before HT
  ingest
- get_marcxml_for_HT.rb - checks for issues with Sierra MARC, generates an
  error report with problem records and marcxml-for-HT for good records
- split_problems_by_branch.rb - splits check_IA_data output into individual
  files for each branch
- mail_the_problems.rb - mails branch problem files to branches
- coll_to_branch_map.yaml - maps IA collections to branches
- branch_emails.yaml - maps branches to emails

Usage
-----
### Generate marcxml for HT ingest / marc problems to be fixed
- Run check_IA_data.rb with a current search.csv
- output from check_IA_data.rb
  - Sort and check over non-problematic IA volume data for unrecognized
    problems. Add notes manually if any found.
  - Remove any records without problems and save as problems.csv
- Run get_marcxml_for_HT.rb
- bib_errors.txt - entries go to cataloging/LDSS to be fixed
- hathi_marcxml.xml - can go to HT for ingest

### Sending IA metadata problems to branches
- Run check_IA_data.rb with a current search.csv
- Run split_problems_by_branch.rb to generate files in branch_problems/
- If there are items with problems in unrecognized collections, those end
  up in "branch_problems/..._ia_problems_unrecognized.csv"
  - Specify mappings for those collections in coll_to_branch_map.txt
  - Re-run split_problems_by_branch.rb
- Remove any of the ia_problems csvs in branch_problems you don't want to mail
- Run mail_the_problems.rb

Details
---------
### check_IA_data.rb
checks for IA metadata to be resolved before HT ingest

Input:
  - search.csv
  - arks file
  - (optional) coll_to_branch_map.yaml (for branch detection)

Output:
  - check_IA_data_for_problems.csv
    - contains all IA records, not just those with problems. Problems are
      listed in the notes column.

      It's worth sorting and checking over the non-problematic ia.volume
      data. If further rules for detecting volume data that needs captions,
      they can be added to IARecord.rb. Those, or any other volume/other
      problems, can have notes manually entered in the notes column. Remove
      any non-problematic records before saving as problems.csv for
      get_marcxml_for_HT

### get_marcxml_for_HT.rb
checks for issues with Sierra MARC, generates an error report with problem
records and marcxml-for-HT for good records

Input:
  - search.csv
  - arks file
  - problems.csv derived from check_IA_data output
    - a list of ia_ids to be excluded from the HT-ingest (until problems are
      resolved). It's derived from the output of check_IA_data.rb. It should
      contain ia_identifiers in the first column, headed 'identifier', and
      should only contain IA items that should
      be excluded

Output:
  - ia_log.csv -- log of all IA records with their status (one of: 'no sierra
    record', 'no IA ark_id found', 'record already in HT', 'failed MARC checks',
   'wrote xml')
  - bib_errors.txt -- txt file of bibs with errors, which are excluded from
    xml file
  - hathi_marcxml.xml -- marcxml for bibs without errors to give to HT

### split_problems_by_branch.rb
splits check_IA_data output into individual files for each branch

Input:
  - check_IA_data_for_problems.csv

### mail_the_problems.rb
mails branch problem files to branches

Input:
  - output of split_problems_by_branch.rb
  - branch_emails.yaml

### Other files
#### search.csv -- (not included here)
is a search results file from Internet Archive for items we're interested in. Both queries below extend back for all time, practically, so adjust the publicdate if you want to look only at items more recently ingested into IA.

This query does not exclude ncdhc items:

https://archive.org/advancedsearch.php?q=scanningcenter%3A(chapelhill)+AND+unc_bib_record_id%3A%5B*+TO+*%5D+AND+publicdate%3A%5B2001-01-03+TO+null&fl%5B%5D=unc_bib_record_id,identifier,identifier-ark,volume,publicdate,sponsor,contributor,collection&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=5000000&page=1&output=csv&callback=callback&save=yes


This query excludes ncdhc items:

https://archive.org/advancedsearch.php?q=scanningcenter%3A(chapelhill)+AND+unc_bib_record_id%3A%5B*+TO+*%5D+AND+publicdate%3A%5B2001-01-03+TO+null%5D+AND+NOT+collection%3A(ncdhc)&fl%5B%5D=unc_bib_record_id,identifier,identifier-ark,volume,publicdate,sponsor,contributor,collection&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=5000000&page=1&output=csv&callback=callback&save=yes

#### nc01.arks.txt -- mid-2017 file included for convenience
is a list of ark ids for all unc-contributed items in HathiTrust as of mid-2017 (which remains current as of Jan 1 2018). It should be updated (i.e. kept current) if you want automated detection of whether a UNC record already exists in HT for an IA item.
'''
awk -F'\t' '($1 ~ /^nc01\./) { gsub(/^nc01\./, "", $1); print $1 }' hathi_full_20180701.txt > nc01.arks.txt
'''



IA-to-Sierra ingest
==================

These can be moved elsewhere or the scope of this repo can be changed to include Sierra-IA-HT utilities. But they're here for now.
