require_relative '../IASierraBib.rb'
require_relative '../IASierra856.rb'
require_relative '../IARecord.rb'


# discards deleted or suppressed bibs with no output/logging
#   TODO: add logging for these
# ouputs stub/partial record mrk suitable for loading
# after altering the batch load note
# combines urls on the same bnum into one record
# creates 856|3 where needed
#   records with non-IA urls (ind2 in [0, 1]) get |3Internet Archive
#   monos with ia.volume content get |3[Internet Archive, ]ia.volume
# sorts 856s by subfield 3 with all numbers padded

# re: distinguish_if_needs_oca
#   if on outputs two files that can be loaded separately with diff profiles

distinguish_if_needs_oca = true


# so load this output, then run checks for dupe_sf3, dismabiguation_needed, sort_double_checking,
# global update duplicate oca item recs unless distinguish_if_needs_oca


ifile = IARecord.import_search_csv('search.csv')
ifile.sort_by! { |r| r[:unc_bib_record_id] }

# input = ia_ids with IA-metadata issues to be excluded from HT-ingest (until fixed)
problem_ids = []
problem_ids = CSV.read('../problems.csv', headers: true)
problem_ids = problem_ids.to_a[1..-1].map { |r| r[0] }
ifile.reject! { |r| problem_ids.include?(r[:identifier])}

# make a hash of bnum : array of IA item objects
bnums = {}
ifile.each do |ia_hash|
  ia = IARecord.new(ia_hash)
  bnum = ia.bib_record_id
  ia_id = ia.id
  if bnums.include?(bnum)
    bnums[bnum] << ia
  else
    bnums[bnum] = [ia]
  end
end


if distinguish_if_needs_oca
  needs_oca_item = MARC::Writer.new('new_ia_urls_NEED_item.mrc')
  has_oca_item = MARC::Writer.new('new_ia_urls_HAVE_item.mrc')
else
  ofile = MARC::Writer.new('new_ia_urls.mrc')
end

bnums.entries.each do |bnum, ia_recs|
  bib = SierraBib.new(bnum)
  bib.ia=(ia_recs)
  puts "del or not  #{bib.given_bnum}" if bib.deleted || bib.record_id == nil
  puts "suppressed  #{bib.given_bnum}" if bib.suppressed?
  #todo: any logging of deleted/suppressed bibs
  next if bib.deleted || bib.record_id == nil || bib.suppressed?

  m856s_needed = bib.m856s_needed
  next unless m856s_needed

  bib.stub << bib.proper_530 unless bib.has_OA_530?
  m856s_needed.each { |m856| bib.stub << m856 }
  if distinguish_if_needs_oca
    bib.stub << bib.proper_949 unless bib.oca_items
  else
    # if we're loading everything together, we always create an item (and
    # delete unneeded items postload)
    bib.stub << bib.proper_949
  end

  if distinguish_if_needs_oca
    ofile = bib.oca_items ? has_oca_item : needs_oca_item
  end
  ofile.write(bib.stub.sort)
end

if distinguish_if_needs_oca
  needs_oca_item.close
  has_oca_item.close
else
  ofile.close
end