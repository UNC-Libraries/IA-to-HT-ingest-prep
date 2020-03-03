#!/usr/bin/env ruby

require_relative '../lib/ia_to_ht_ingest_prep.rb'

# skip any ia items with in 'ncdhc' collection?
skip_ncdhc = true

ifile = IaToHtIngestPrep::IaRecord.import_search_csv('search.csv')
ifile.sort_by! { |r| r[:unc_bib_record_id] }
arks = File.read('nc01.arks.txt').split("\n")

bnums = {}
ifile.each do |ia_hash|
  ia = IaToHtIngestPrep::IaRecord.new(ia_hash)
  next if skip_ncdhc && ia.branch == 'ncdhc'
  bnum = ia.bib_record_id
  if bnums.include?(bnum)
    bnums[bnum] << ia
  else
    bnums[bnum] = [ia]
  end
end

ofile = CSV.open('problems.csv', 'w')
headers = %w[identifier URL priority problems bnum bib_record_id ia.volume
             ia_rec_ct_on_bnum in_ht? link_in_sierra? notHT_ct_on_bnum ark
             publicdate sponsor contributor collection branch]
ofile << headers
prev_bnum = 'unlikely_initial_string'
prev_bib = nil
bnums.entries.each do |temp_bnum, ia_recs|
  bib =
    if temp_bnum == prev_bnum
      prev_bib
    else
      begin
        IaToHtIngestPrep::IaBib.new(Sierra::Record.get(temp_bnum))
      rescue Sierra::Record::InvalidRecord
        IaToHtIngestPrep::IaBib.new(nil)
      end
    end
  prev_bnum = temp_bnum
  prev_bib = bib

  # sort by (padded) ia.volume
  ia_recs.sort_by! {
    |ia| ia.volume.to_s.gsub(/([0-9]+)/) do |m|
      $1.rjust(10, '0')
    end
  }
  bib.ia_items = ia_recs
  bib.not_in_ht_item_count =
    bib.ia_items.reject { |irec| arks.include?(irec.ark) }.length

  ia_recs.each do |ia|
    checker = IaToHtIngestPrep::IaItemChecker.new(bib, ia)
    checker.in_ht = arks.include?(ia.ark)
    if ia.branch == 'unrecognized' && checker.notes.any?
      puts "unknown coll w problem. bib:#{bib.bnum} coll: #{ia.hsh[:collection].to_s}"
    end
    ofile << checker.output_row if checker.problems?
  end
end

