require_relative 'SierraArchiveURL.rb'
require_relative '../IASierraBib.rb'
require_relative '../IASierra856.rb'
require_relative '../IARecord.rb'
require_relative '../../sierra_postgres_utilities/SierraBib.rb'


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
  and sf_x.tag = 'x'
left join sierra_view.subfield sf_y on sf_y.varfield_id = v.id
  and sf_y.tag = 'y'
where v.marc_tag = '856'
and v.field_content ~* 'archive.org'
--and v.field_content !~* 'url_tagged_for_replacement_'
order by bnum
SQL

$c.close if $c
$c = Connect.new()

$c.make_query(query)


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
$c.results.entries.each do |m856|
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
    ofile << [url.bnum, url.notes.join(';;;')]
    next
  end
  my_ia =
    if url.ia_id 
      ia_by_ident[url.ia_id]
    elsif url.url_bib_record_id
      ia_by_bibrecid[url.url_bib_record_id].to_a[0]
    end
  url.ia=(my_ia)
  unless url.ia
    url.notes << 'ia_id or bib_record_id not found in IA'
    ofile << [url.bnum, url.notes.join(';;;')]
    next
  end
  puts temp_bnum
  unless url.proper
    puts temp_bnum
  end
  url.do_checks
  bnum = url.bib.trunc_bnum
  ofile << [
    url.bnum,
    url.notes.join(';;;'),
    url.bib.bib_locs,
    url.bib.bcode1_blvl,
    url.bib.mat_type,
    url.ia_id.to_s,
    url.sfu,
    url.sf3,
    url.sfx,
    url.sfy,
    url.bib.trunc_bnum,
    url.url_bib_record_id.to_s,
    url.is_orig_print_rec?.to_s,
    url.urls_sierra_bib_should_have(ia_by_bibrecid[bnum]),
    url.oca_stats_count.to_s,
    url.have_jurisdiction?.to_s,
    url.proper.proper_sf3.to_s,
    url.proper.proper_sfu.to_s,
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
#don't batch things with notes.
# don't batch things with uneditable_url_count > 0




#get count of archive urls seirra bib does have
# if the counts match



=begin
$c.results.entries.each do |m856|
  bnum = m856['bnum']
  short_bnum = bnum[0..7]
  notes = []
  unless m856['sfu'] =~ /archive\.org/
    notes << 'no archive.org url in 856$u'
    ofile << [bnum, notes.join(';;;')]
    next
  end
  sf3 = m856['sf3'].to_s
  sfx = m856['sfx'].to_s
  sfy = m856['sfy'].to_s
  sfu = m856['sfu'].to_s
  oca_stats_count = m856['oca_stats_count'].to_s
  blvl = m856['bcode1']
  mat_type = m856['bcode2']
  m = m856['sfu'].match(/details\/(.*)/)
  if m 
    ia_id = m[1]
    ia = ia_by_ident[ia_id]
  end
  m2 = m856['sfu'].match(/call_number[^b]*(b[0-9]*)/)
  if m2
    url_call_number = m2[1]
    url_bib_record_id = url_call_number[0..7]
  end
  unless ia_by_ident.include?(ia_id) or ia_by_bibrecid.include?(url_bib_record_id)
    notes << 'ia_id or bib_record_id not found in IA'
    ofile << [bnum, notes.join(';;;')]
    next
  end
  if ['s', 'b'].include?(blvl)
    notes << 'serial has sf3 content' unless sf3.empty?
    notes << 'serial has detail url' if ia_id
    urls_sierra_bib_should_have = 1
    proper_url_type = 'serial'
    proper_bib_record_id = url_bib_record_id ? url_bib_record_id : ia.misc[0]
  end
  if ['a', 'c', 'm'].include?(blvl)
    notes << 'mono identifier not found in IA' if ia_id && !ia
    notes << 'mono sf3 content does not match IA' unless ia && sf3 == ia.volume
    notes << 'mono has query url' unless ia_id
    urls_sierra_bib_should_have = ''
    urls_sierra_bib_should_have = ia_by_bibrecid[ia.misc[0]].length if ia
    proper_url_type = 'mono'
  end
  if url_bib_record_id == short_bnum || (ia && ia.misc[0] == short_bnum)
    is_orig_print_rec = 'yes'
  else
    is_orig_print_rec = 'no'
  end
  have_jurisdiction = is_orig_print_rec == 'yes' || !oca_stats_count.empty?
  if sfy != 'Full text available via the UNC-Chapel Hill Libraries'
    notes << 'has non-standard 856$y'
  end
  unless sfx.empty?
    notes << 'has populated 856$x'
  end
  proper_sf_y = '|yFull text available via the UNC-Chapel Hill Libraries'
  #proper_sf_x = '|xauto-generated OCA 856'
  if proper_url_type == 'serial'
    proper_sf_u = "|uhttps://archive.org/search.php?sort=publicdate&query=scanningcenter%3Achapelhill+AND+mediatype%3Atexts+AND+unc_bib_record_id%3A#{proper_bib_record_id}"
    proper_url = proper_sf_u + proper_sf_y
  elsif proper_url_type == 'mono'
    if ia_id
      proper_sf_3 = "|3#{ia.volume}" if !ia.volume.empty?
      proper_sf_u = "|uhttps://archive.org/details/#{ia_id}"
      proper_url = proper_sf_3.to_s + proper_sf_u + proper_sf_y
    end
  end
  if ia_id
    ofile << [bnum, notes.join(';;;'), blvl, mat_type, ia_id, sfu, sf3, sfx, sfy,
      short_bnum, '',
      is_orig_print_rec, urls_sierra_bib_should_have, oca_stats_count, have_jurisdiction, proper_url.to_s
    ]
  else
    ofile << [bnum, notes.join(';;;'), blvl, mat_type, '', sfu, sf3, sfx, sfy,
      short_bnum, url_bib_record_id,
      is_orig_print_rec, urls_sierra_bib_should_have, oca_stats_count, have_jurisdiction, proper_url.to_s
  ]
  end
end
ofile.close
=end


=begin
  
our oca things seem to be things:
  is_orig_print_rec == yes
  or has oca statsed item record
  if neither of those, it if mat_type z/s/w check and add oca statsed item if ours?
  
=end


#  when outputting mark, properly sort vols (incl v.5 before v.1 or v.400)
#  even if sierra rec contains duplicate urls, don't output duplicate good urls