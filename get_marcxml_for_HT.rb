
require 'csv'
require_relative 'HathiRecord'

$c.close if $c
$c = Connect.new


# input = IA search.csv results for prospective HT-ingest
#   essential fields: bnum, id, ark, vol
#   standard addl fields: publicdate, sponsor, contributor, collection
# see readme for query link(s)
ifile = IARecord.import_search_csv('search.csv')
headers = ifile[0].keys
ifile.sort_by! { |r| r[:unc_bib_record_id] }

# input = arks UNC contributed to HT to date
arks = File.read('nc01.arks.txt').split("\n")

# input = ia_ids with IA-metadata issues to be excluded from HT-ingest (until fixed)
problem_ids = []
if File.file?('problems.csv')
  problem_ids = CSV.read('problems.csv', headers: true)
  problem_ids = problem_ids.to_a[1..-1].map { |r| r[0] }
end

# input = bib_record_ids to be excluded from HT-ingest
#   e.g. some sheet music bibs that were scribed but it was decided should
#     not be sent to HT
# if at some point we also want to exclude certain ia_ids (instead of bibs),
# we can add that
exclude_bibs = File.read('ht_exclude_bib.txt').split("\n")
exclude_bibs.select! { |x| x =~ /^b[0-9]+$/ }

# this logs details of bib/marc errors
err_log = File.open('bib_errors.txt', 'w')
# this logs general disposition of everything
$ia_logfile = CSV.open('ia_log.csv', 'w')
$ia_logfile << ['reason', headers].flatten


def ia_log(reason, ia_record)
  $ia_logfile << [reason, ia_record.to_a].flatten
end


problem_id_exclusion = 0
File.open('hathi_marc.xml',"w:UTF-8") do |xml_out|
  xml_out << MARC::XML_HEADER
  prev_bnum = nil
  prev_bib = nil
  ifile.each do |ia_record|
    ia = IARecord.new(ia_record)
    p ia
    bnum = ia.bib_record_id
    if exclude_bibs.include?(bnum)
      ia_log('bib blacklisted', ia_record)
      next
    end
    if problem_ids&.include?(ia.id)
      problem_id_exclusion += 1
      ia_log('on problems.csv', ia_record)
      next
    end
    if prev_bnum == bnum
      bib = prev_bib
    else
      bib = SierraBib.new(bnum)
    end
    hathi = HathiRecord.new(bib, ia)
    puts bnum

    if !hathi.warnings.empty?
      ia_log('no sierra record', ia_record)
    elsif !hathi.ia.ark
      ia_log('no IA ark_id found', ia_record)
    elsif arks.include?(hathi.ia.ark)
      ia_log('record already in HT', ia_record)
    elsif !hathi.manual_write_xml(outfile: xml_out,
                                  strict: true)
      ia_log('failed MARC checks', ia_record)
      hathi.warnings.each do |warning|
        err_log << "#{hathi.bnum}\t#{warning}\n"
      end
    else
      ia_log('wrote xml', ia_record)
    end

    prev_bnum = bnum
    prev_bib = bib
  end
  xml_out << MARC::XML_FOOTER
end
err_log.close
$ia_logfile.close

errors = File.read('bib_errors.txt').split("\n")
errors.insert(0, "na\tExcluded #{problem_id_exclusion} ids of the #{problem_ids.length} ids on problems.csv due to...problems. LDSS, if this count is not what you expected, examine.")
File.write('bib_errors.txt', errors.uniq.join("\n"))
