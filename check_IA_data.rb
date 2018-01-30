load 'IASierraBib.rb'
load 'IASierra856.rb'
load 'IARecord.rb'


ifile = IARecord.import_search_csv('search.csv')
ifile.sort_by! { |r| r[:unc_bib_record_id] }
arks = File.read('nc01.arks.txt').split("\n")

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

ofile = CSV.open('check_IA_data_for_problems.csv', 'w')
headers = %w(identifier problems bnum bib_record_id ia.volume ia_rec_ct_on_bnum HTstatus ark publicdate sponsor contributor collection)
ofile << headers
prev_bnum = 'unlikely_initial_string'
prev_bib = nil
bnums.entries.each do |temp_bnum, ia_recs|
  puts temp_bnum
  if temp_bnum == prev_bnum
    bib = prev_bib
  else
    bib = SierraBib.new(temp_bnum)
    prev_bnum = temp_bnum
    prev_bib = bib
  end
  bnum = bib.bnum
  bib.ia=(ia_recs)
  ia_count_by_vol = bib.ia_count_by_vol
  # sort by ia.volume, pad any numbers
  ia_recs.sort_by! { |ia| ia.volume.to_s.gsub(/([0-9]+)/, '\1'.rjust(10, '0')) }
  ia_recs.each do |ia|
    puts ia.id
    notes = []
    if bib.record_id
      notes << 'bib suppressed' if bib.suppressed
    else
      notes << 'bib deleted' 
    end
    unless bib.ia.select { |ia| ia.lacks_caption }.empty?
      # if bib has any ia with vol info that lacks caption
      # may as well warn about any on bib, such that with "v.2" and "2"
      # we'll reject both and process as dupes, rather than permit the "v.2"
      # and later find the "2" is a dupe
      if ia.lacks_caption
        notes << 'this ia_rec lacks a caption'
      else
        notes << 'other ia_rec on bib lacks a caption'
      end
    end
    #if bib.has multiple recs with no vol info
    if ia_count_by_vol[''] && ia_count_by_vol[''] > 1
      notes << 'bib has multiple recs with no vol info'
    end
    #if bib had 1 rec with no vol info and other recs with info
    if ia_count_by_vol.length > 1 and ia_count_by_vol['']
      notes << 'bib has rec(s) that lack likely-needed vol info'
    end
    #if bib is serial and ia has no vol info
    # bib.record_id check skips this for deleted bibs
    if bib.record_id && bib.serial? && ia.volume.empty?
      notes << 'bib is a serial and lacks vol info'
      #warn true
    end
    #if ia has other rec in ia with same vol info
    if !ia.volume.empty? && ia_count_by_vol[ia.volume] > 1
      notes << 'other ia_rec on bib has same vol info'
    end
    htstatus = arks.include?(ia.ark) ? 'ark_in_HT' : 'ark_not_in_HT'
    ofile << [
      ia.id,
      notes.join(';;;'),
      bib.bnum,
      ia.bib_record_id,
      ia.volume,
      bib.ia.length.to_s,
      htstatus,
      ia.ark,
      ia.hsh[:publicdate].to_s,
      ia.hsh[:sponsor].to_s,
      ia.hsh[:contributor].to_s,
      ia.hsh[:collection].to_s,
    ]
  end
end
