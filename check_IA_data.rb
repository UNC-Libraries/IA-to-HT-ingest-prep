require_relative 'IASierraBib'
require_relative 'IASierra856'
require_relative 'IARecord'

# skip any ia items with in 'ncdhc' collection?
skip_ncdhc = true

ifile = IARecord.import_search_csv('search.csv')
ifile.sort_by! { |r| r[:unc_bib_record_id] }
arks = File.read('nc01.arks.txt').split("\n")

bnums = {}
ifile.each do |ia_hash|
  ia = IARecord.new(ia_hash)
  next if skip_ncdhc && ia.branch == 'ncdhc'
  bnum = ia.bib_record_id
  ia_id = ia.id
  if bnums.include?(bnum)
    bnums[bnum] << ia
  else
    bnums[bnum] = [ia]
  end
end

ofile = CSV.open('check_IA_data_for_problems.csv', 'w')
headers = %w(identifier URL priority problems bnum bib_record_id ia.volume
             ia_rec_ct_on_bnum HTstatus link_in_sierra? notHT_ct_on_bnum ark
             publicdate sponsor contributor collection branch)
ofile << headers
prev_bnum = 'unlikely_initial_string'
prev_bib = nil
bnums.entries.each do |temp_bnum, ia_recs|
  #puts temp_bnum
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
  ia_recs.sort_by! {
    |ia| ia.volume.to_s.gsub(/([0-9]+)/) do |m|
      $1.rjust(10, '0')
    end
  }
  not_HT_bib_count = bib.ia.reject { |irec| arks.include?(irec.ark) }.length
  ia_recs.each do |ia|
    #puts ia.id
    notes = []
    notes << 'bib deleted' if bib.deleted?
    notes << 'bib suppressed' if bib.suppressed?
    link_in_sierra =
      if bib.serial?
        bib.has_query_url?
      elsif bib.mono?
        bib.ia_ids_in_856u.to_a.include?(ia.id)
      end
    unless bib.ia.select { |ia| ia.lacks_caption? }.empty?
      # if bib has any ia with vol info that lacks caption
      # may as well warn about any on bib, such that with "v.2" and "2"
      # we'll reject both and process as dupes, rather than permit the "v.2"
      # and later find the "2" is a dupe
      if ia.lacks_caption?
        # serial captions only affect HT/IA not Sierra links
        # mono captions affect HT/IA and Sierra links
        # if a serial is already in HT, lacks caption is not so big a problem,
        # but monos already in HT still need captions for proper Sierra links.
        notes << "CAPTION:this IA #{bib.rec_type} lacks caption"
        needs_fix = true
      else
        notes << 'other IA item on bib lacks caption'
      end
    end
    # if ia has no vol info but bib is mvmono or serial
    if !ia.volume && ( bib.ia.length > 1 || (!bib.deleted? && bib.serial?))
      notes << 'DISAMBIGUATE:this IA item needs volume'
      needs_fix = true
    # if bib.has multiple recs and >0 recs lack volume data
    elsif ia_count_by_vol[nil] && (ia_count_by_vol[nil] > 1 || ia_count_by_vol.length > 1)
      notes << 'other IA items on bib need volume disambiguation'
    end
    # if ia has other rec in ia with same vol info (and vol info exists)
    if ia.volume && ia_count_by_vol[ia.volume] > 1
      notes << 'DUPE?: bib has >1 IA item with this volume'
      needs_fix = true
    end
    priority = nil
    # priority 1 - things not in HT
    # priority 2 - things in HT, except the below
    # priority 3 - serials in HT that only need captions
    # priority nil - anything that doesn't itself need fixing
    if arks.include?(ia.ark)
      htstatus = 'ark_in_HT'
      if needs_fix
        if notes == ['CAPTION:this IA serial lacks caption']
          priority = 3
        else
          priority = 2
        end
      end
    else
      htstatus = 'ark_not_in_HT'
      priority = 1 if needs_fix
    end
    if ia.branch == 'unrecognized' && !notes.empty?
      puts "unknown coll w problem. bib:#{bib.bnum} coll: #{ia.hsh[:collection].to_s}"
    end
    ofile << [
      ia.id,
      "https://archive.org/details/#{ia.id}",
      priority,
      notes.join(';;;'),
      bib.bnum,
      ia.bib_record_id,
      ia.volume,
      bib.ia.length.to_s,
      htstatus,
      link_in_sierra.to_s,
      not_HT_bib_count.to_s,
      ia.ark,
      ia.hsh[:publicdate].to_s,
      ia.hsh[:sponsor].to_s,
      ia.hsh[:contributor].to_s,
      ia.hsh[:collection].to_s,
      ia.branch
    ]
  end
end

