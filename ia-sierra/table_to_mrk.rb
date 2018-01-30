require 'csv'

loadnote = 'Batch load history: 17412 OCA records to fix URLs loaded 20180118, jcm.'

fixing_mono_queries = false
#fixing_mono_queries = true

ifile = 'table_to_convert.csv' unless fixing_mono_queries
ifile = 'archive_url_check_out_fix-mono-queries.csv' if fixing_mono_queries

recs = CSV.read(ifile, headers: true)
recs = recs.sort_by { |r| r[0] }

uneditable_bnums = []
imperfect_bnums = []
recs.each do |rec|
  bnum = rec[0]
  #rec['notes'] = nil if fixing_mono_queries
  unless !rec['notes'] && rec['have_jurisdiction'] =~ /true/i
    uneditable_bnums << bnum
  end
  unless rec['perfect_856'] =~ /true/i
    imperfect_bnums << bnum
  end
end

ofile = File.open('archive_url_check_out.mrk', 'w')
edited_bnums = []
prev_bnum = ''
recs.each do |rec|
  bnum = rec[0]
  next if uneditable_bnums.include?(bnum)
  next unless imperfect_bnums.include?(bnum)
  if fixing_mono_queries
    next unless rec['all_proper_856s']
  end
  unless bnum == prev_bnum
    edited_bnums << bnum
    ofile << "=944  \\\\$a#{loadnote}\r\n"
    ofile << "\r\n"
    ofile << rec['fake_leader'] + "\r\n"
    ofile << rec['proper_907'] + "\r\n"
    ofile << rec['all_proper_856s'].split(';;;').join("\r\n") + "\r\n" if fixing_mono_queries
  end
  ofile << rec['proper_856'] + "\r\n" unless fixing_mono_queries
  prev_bnum = bnum
end
ofile << "=944  \\\\$a#{loadnote}\r\n"
ofile.close

File.write('archive_url_check_out_edited_bnums.txt',
           edited_bnums.join("\n"))