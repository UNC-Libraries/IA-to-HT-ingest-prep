#!/usr/bin/env ruby

require 'csv'
require 'marc'
require_relative '../lib/ia_to_ht_ingest_prep.rb'

ifile = IaToHtIngestPrep::IaRecord.import_search_csv('search.csv.includes')
ifile.sort_by! { |r| r[:unc_bib_record_id] }

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
ia_ids = bnums.values.flatten.map { |ia| [ia.id, ia] }.to_h

ocalink_bibs = Sierra::Data::Varfield.
               where(marc_tag: '856').
               where(Sequel.like(:field_content, '%|xocalink_j%')).
               bibs

bnum_ofile = File.open('remove_unneeded_ia_urls.bnum', 'w')
mrc = MARC::Writer.new('remove_unneeded_ia_urls.mrc')
csv = CSV.open('unneeded_ia_urls.txt', 'w')
ocalink_bibs.each do |sierra_bib|
  deletion_needed = false
  good_fields = []
  bib = IaToHtIngestPrep::IaBib.new(sierra_bib)
  #
  # Iterate through all the 856s on bibs with ocalinks
  # Records where no 856s needed to be deleted get discarded
  # Records where an 856 needs to be deleted:
  #   we'll delete any 856s on the record
  #   we'll load any good 856s onto the record
  #   any bad ocalink 856s will not be loaded back onto the record
  #   if removing bad ocalink 856(s) from a record will result in the record
  #     having no 856s, look at it to assess whether it still needs any e-ness.
  #     But one example of this could be a mono record that has serial/query
  #     url (or vice versa). The serial url needs to be deleted, there will
  #     be no url on the record, but we need to add a mono url.
  # So, for records with an empty good_fields, we don't write to marc, but we
  #   do log the deletion to file

  all_856s = bib.marc.fields('856')
  all_856s.each do |m856|
    unless m856.value =~ /ocalink_j?cm/
      # it's not an ocalink. write it.
      good_fields << m856
      next
    end

    url = SierraArchiveURL.new(field: m856, bib: bib)
    if url.ia_id &&
      if bib.serial?
        # mono url on serial bib. delete.
        csv << [url.bnum, url.ia_id, nil, url.url, 'mono url from serial record']
        deletion_needed = true
      elsif url.ind2 == '0'
        # e-record
        # its bnum should not be present in bnums as a bib_record_id
        # if ia_id is not present anywhere in bnums, delete the url
        if ia_ids.include?(url.ia_id)
          good_fields << url.field
        else
          csv << [url.bnum, url.ia_id, nil, url.url, 'mono url from e-record']
          deletion_needed = true
        end
      else
        # print record
        # its bnum should be present in bnums as a bib_record_id
        # if bnum is not present in bnums, delete url
        # if ia_id is not present in bnums[bnum], delete url
        # it's also possible the url has the wrong ind2 and the record is not
        #   really a print record
        allowed_ids = bnums[url.bnum.chop]&.map(&:id)
        if allowed_ids&.include?(url.ia_id)
          good_fields << url.field
        else
          csv << [url.bnum, url.ia_id, nil, url.url, 'mono url from print record']
          deletion_needed = true
        end
      end
    elsif url.url_bib_record_id
      if bib.mono?
        # serial url on mono bib. delete.
        csv << [url.bnum, nil, url.url_bib_record_id, url.url, 'serial url on mono record']
        deletion_needed = true
      elsif bnums.include?(url.url_bib_record_id)
        # don't write query url to good_fields if an identical one is already there
        unless good_fields.map(&:value).include?(url.field.value)
          good_fields << url.field
        end
      else
        # delete url if url's bib_record_id is not in bnums
        csv << [url.bnum, nil, url.url_bib_record_id, url.url, 'serial']
        deletion_needed = true
      end
    else
      # generally shouldn't happen. tile-based query urls should show up here though?
      csv << [url.bnum, url.ia_id.to_s, url.url_bib_record_id.to_s, url.url.to_s, 'title-query-url or some other weirdness']
    end
  end # looping through 856s

  next unless deletion_needed

  # if deletion is needed, write marc and write bnums to file
  bnum_ofile << "#{bib.bnum}\n"
  if good_fields.empty?
    csv << [bib.bnum, nil, nil, nil, 'this bib will no longer have ANY urls']
  else
    mrc.write(IaToHtIngestPrep::IaBibMarcStub.new(bib).stub(good_fields))
  end
end
bnum_ofile.close
mrc.close
csv.close
