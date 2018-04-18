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

# so load this output, then run checks for dupe_sf3, dismabiguation_needed, sort_double_checking,
# global update duplicate oca item recs unless distinguish_if_needs_oca

distinguish_if_needs_oca = true

def sortable_sf3(m856)
  sf3 = m856.match(/\|3[^|]*/)
  return '' unless sf3
  sf3.to_s.gsub(/([0-9]+)/) do |m|
    $1.rjust(10, '0')
  end
end

def to_marcedit(string)
  string = string.to_s.gsub('|', '$')
  return string + "\r\n"
end

$c.close if $c
$c = Connect.new

ifile = IARecord.import_search_csv('search.csv')
ifile.sort_by! { |r| r[:unc_bib_record_id] }

# input = ia_ids with IA-metadata issues to be excluded from HT-ingest (until fixed)
problem_ids = []
problem_ids = CSV.read('../problems.csv', headers: true)
problem_ids = problem_ids.to_a[1..-1].map { |r| r[0] }
ifile.reject! { |r| problem_ids.include?(r[:identifier])}

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


blah = ''
if distinguish_if_needs_oca
  needs_oca_item = File.open('new_ia_urls_NEED_item.mrk', 'w')
  has_oca_item = File.open('new_ia_urls_HAVE_item.mrk', 'w')
else
  ofile = File.open('new_ia_urls.mrk', 'w')
end
bnums.entries.each do |bnum, ia_recs|
  bib = SierraBib.new(bnum)
  bib.ia=(ia_recs)
  blah = bib
  puts "del or not  #{bib.given_bnum}" if bib.deleted || bib.record_id == nil
  puts "suppressed  #{bib.given_bnum}" if bib.suppressed
  #todo: any logging of deleted/suppressed bibs
  next if bib.deleted || bib.record_id == nil
  next if bib.suppressed
  if distinguish_if_needs_oca
    ofile = bib.has_oca_ebnb_item? ? has_oca_item : needs_oca_item
  end
  m856s_needed = bib.m856s_needed
  next unless m856s_needed
  ofile << to_marcedit(bib.fake_leader)
  ofile << to_marcedit(bib.proper_907)
  ofile << to_marcedit(bib.proper_530) unless bib.has_OA_530?
  m856s_needed.sort_by! { |m856| sortable_sf3(m856) }
  m856s_needed.each { |m856| ofile << to_marcedit(m856) }
  if distinguish_if_needs_oca
    ofile << to_marcedit(bib.proper_949) unless bib.has_oca_ebnb_item?
  else
    ofile << to_marcedit(bib.proper_949)
  end
  ofile << to_marcedit(bib.stub_load_note)
  ofile << "\r\n"
end
if distinguish_if_needs_oca
  needs_oca_item.close
  has_oca_item.close
else
  ofile.close
end