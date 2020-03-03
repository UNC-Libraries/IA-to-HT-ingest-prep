#!/usr/bin/env ruby

require_relative '../lib/ia_to_ht_ingest_prep.rb'

# discards deleted or suppressed bibs with no output/logging
#   TODO: add logging for these
# ouputs stub/partial record mrk suitable for loading
# after altering the batch load note
# combines urls on the same bnum into one record
# creates 856|3 where needed
#   records with non-IA urls (ind2 in [0, 1]) get |3Internet Archive
#   monos with ia.volume content get |3[Internet Archive, ]ia.volume
# sorts 856s by subfield 3 with all numbers padded


# so load this output, then run checks for dupe_sf3, dismabiguation_needed, sort_double_checking,
# global update duplicate oca item recs unless distinguish_if_needs_oca


ifile = IaToHtIngestPrep::IaRecord.import_search_csv('search.csv')
ifile.sort_by! { |r| r[:unc_bib_record_id] }

# input = ia_ids with IA-metadata issues to be excluded from HT-ingest (until fixed)
problem_ids = []
problem_ids = CSV.read('problems.csv', headers: true)
problem_ids = problem_ids.to_a[1..-1].map { |r| r[0] }
ifile.reject! { |r| problem_ids.include?(r[:identifier])}

# make a hash of bnum : array of IA item objects
bnums = {}
ifile.each do |ia_hash|
  ia = IaToHtIngestPrep::IaRecord.new(ia_hash)
  bnum = ia.bib_record_id
  if bnums.include?(bnum)
    bnums[bnum] << ia
  else
    bnums[bnum] = [ia]
  end
end

needs_oca_item = MARC::Writer.new('new_ia_urls_NEED_item.mrc')
has_oca_item = MARC::Writer.new('new_ia_urls_HAVE_item.mrc')

bnums.entries.each do |bnum, ia_recs|
  bib =
    begin
      IaToHtIngestPrep::IaBib.new(Sierra::Record.get(bnum))
    rescue Sierra::Record::InvalidRecord
      IaToHtIngestPrep::IaBib.new(nil)
    end

  # We should have already excluded bibs that are deleted/suppressed or where
  # the bib_record_id is an invalid bnum, but just in case
  if bib.invalid? || bib.deleted? || bib.suppressed?
    puts "invalid #{bnum}" if bib.invalid?
    puts "del or not  #{bnum}" if bib.deleted?
    puts "suppressed  #{bnum}" if bib.suppressed?
    next
  end

  bib.ia_items = ia_recs

  m856s_needed = bib.m856s_needed
  next unless m856s_needed

  ofile = bib.oca_items ? has_oca_item : needs_oca_item
  ofile.write(IaToHtIngestPrep::IaBibMarcStub.new(bib).stub(m856s_needed))
end

needs_oca_item.close
has_oca_item.close

