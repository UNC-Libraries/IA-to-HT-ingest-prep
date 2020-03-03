#!/usr/bin/env ruby

# WARNING: This script may need to be updated in order to work. Whether we
# still need it is questionable. Purpose was to check OCA urls existing in
# Sierra for correctness.

require_relative 'SierraArchiveURL'
require_relative '../IASierraBib'
require_relative '../IASierra856'
require_relative '../IARecord'
require_relative '../../sierra-postgres-utilities/lib/sierra_postgres_utilities'


query = <<-SQL
select 'b' || record_num || 'a' as bnum,
       v.field_content, sf_3.content as sf3, sf_u.content as sfu,
      sf_x.content as sfx, sf_y.content as sfy, v.marc_ind2 as ind2, *
from sierra_view.varfield v
inner join sierra_view.record_metadata rm on rm.id = v.record_id
inner join sierra_view.bib_record b on b.id = rm.id
left join sierra_view.subfield sf_u on sf_u.varfield_id = v.id
  and sf_u.tag = 'u'
left join sierra_view.subfield sf_3 on sf_3.varfield_id = v.id
  and sf_3.tag = '3'
left join sierra_view.subfield sf_x on sf_x.varfield_id = v.id
  and sf_x.tag = 'x' and sf_x.content !~* 'ocalink_jcm'
left join sierra_view.subfield sf_y on sf_y.varfield_id = v.id
  and sf_y.tag = 'y'
where v.marc_tag = '856'
and v.field_content ~* '\\|xocalink_j.m'
--and v.field_content ~* 'archive\.org'
--and v.field_content !~* 'url_tagged_for_replacement_'
order by bnum
SQL

SierraDB.make_query(query)


ifile = IARecord.import_search_csv('search.csv')
ifile.sort_by! { |r| r[:unc_bib_record_id] }

ia_by_ident = {}
ia_by_bibrecid = {}
ifile.each do |ia_rec|
  ia = IARecord.new(ia_rec)
  bnum = ia.bib_record_id
  ia_by_ident[ia.id] = ia
  if ia_by_bibrecid.include?(bnum)
    ia_by_bibrecid[bnum] << ia
  else
    ia_by_bibrecid[bnum] = [ia]
  end
end

puts ia_by_bibrecid.length
puts ia_by_ident.length

ofile = CSV.open('check_Sierra_IA_urls.csv', 'w')
ofile << %w( bnum notes bib_locs blvl mat_type ia_id sfu sf3 sfx sfy short_bnum url_bib_record_id
             is_orig_print_rec proper_url_count oca_stats_count have_jurisdiction proper_sf3 proper_sfu proper_856_content perfect_856 fake_leader proper_907 proper_856 all_proper_856s)
prev_bnum = 'unlikely_initial_string'
prev_bib = nil
SierraDB.results.entries.each do |m856|
  # intialize new SierraBib or re-use previous
  temp_bnum = m856['bnum']
  if temp_bnum == prev_bnum
    bib = prev_bib
  else
    bib = SierraBib.new(temp_bnum)
    prev_bnum = temp_bnum
    prev_bib = bib
  end
  url = SierraArchiveURL.new(m856, bib: bib)
  if url.has_no_archive_856u?
    ofile << [url.bnum, url.notes.join(';;;'), '', '', url.ia_id.to_s, url.sfu, url.sf3, url.sfx, url.sfy, '', url.url_bib_record_id.to_s]
    next
  end
  # identify URL's IA record
  #   for detail urls, based on ia id
  #   for query urls, grab one IA rec with same unc_bib_record_id
  my_ia =
    if url.ia_id
      ia_by_ident[url.ia_id]
    elsif url.url_bib_record_id
      ia_by_bibrecid[url.url_bib_record_id].to_a[0]
    end
  if my_ia
    url.ia=(my_ia)
  else
    url.notes << 'ia_id or bib_record_id not found in IA'
    ofile << [url.bnum, url.notes.join(';;;'), '', '', url.ia_id.to_s, url.sfu, url.sf3, url.sfx, url.sfy, '', url.url_bib_record_id.to_s]
    next
  end
  puts temp_bnum
  url.do_checks
  bnum = url.bib.bnum
  bnum_trunc = url.bib.bnum_trunc
  ofile << [
    bnum,
    url.notes.join(';;;'),
    url.bib.bib_locs.join(', '),
    url.bib.bcode1_blvl,
    url.bib.mat_type,
    url.ia_id.to_s,
    url.sfu,
    url.sf3,
    url.sfx,
    url.sfy,
    bnum_trunc,
    url.url_bib_record_id.to_s,
    url.is_orig_print_rec?.to_s,
    url.urls_sierra_bib_should_have(ia_by_bibrecid[bnum_trunc]),
    url.oca_stats_count.to_s,
    url.have_jurisdiction?.to_s,
    url.proper.proper_sf3.to_s,
    url.proper.proper_sfu.to_s,
    # fix for removal of proper_856_content
    url.proper.proper_856_content.to_s,
    url.sierra_856_perfect?.to_s,
    url.bib.fake_leader,
    url.bib.proper_907.to_s,
    url.proper.proper_856.to_s.tr('|', '$'),
    url.all_proper_856s(ia_by_bibrecid[bnum]).to_s,
  ]
end
ofile.close



# don't edit things w/o have_jurisdiction
# don't batch things with notes.
# don't batch things with uneditable_url_count > 0


=begin
our oca things seem to be things:
  is_orig_print_rec == yes
  or has oca statsed item record
  if neither of those, it if mat_type z/s/w check and add oca statsed item if ours?

=end

#  even if sierra rec contains duplicate urls, don't output duplicate good urls
