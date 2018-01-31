
require 'csv'
load 'HathiRecord.rb'

$c.close if $c
$c = Connect.new

xml_header = <<-XML
<?xml version='1.0'?>
  <collection xmlns='http://www.loc.gov/MARC21/slim' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'>
XML
xml_footer = '</collection>'

=begin
bnum = 'b2095085'
bib = SierraBib.new(bnum)
ia = IARecord.new('quincediasenital551vald', 'ark:/13960/t0fv1tg4z', 'v. 551')
hathi = HathiRecord.new(bib, ia)
=end

=begin
query not limited by date or by ncdhc collection status
https://archive.org/advancedsearch.php?q=scanningcenter%3A(chapelhill)+AND+unc_bib_record_id%3A%5B*+TO+*%5D+AND+publicdate%3A%5B2001-01-03+TO+null&fl%5B%5D=unc_bib_record_id,identifier,identifier-ark,volume,publicdate,sponsor,contributor,collection&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=5000000&page=1&output=csv&callback=callback&save=yes

=end

# input = IA search.csv results for prospective HT-ingest
# essential fields: bnum, id, ark, vol
# standard addl fields: publicdate, sponsor, contributor, collection
ifile = IARecord.import_search_csv('search.csv')
headers = ifile[0].keys
#ifile.sort_by! { |r| r[:unc_bib_record_id] }

# input = arks UNC contributed to HT to date
arks = File.read('nc01.arks.txt').split("\n")

# input = ia_ids with IA-metadata issues to be excluded from HT-ingest (until fixed)
if File.file?('problems.csv')
  problem_ids = CSV.read('problems.csv', headers: true)
  problem_ids = problem_ids.to_a[1..-1].map { |r| r[0] }
end


# this logs details of bib/marc errors
$err_log = File.open('bib_errors.txt', 'w')
# this logs general disposition of everything
$ia_logfile = CSV.open('ia_log.csv', 'w')
$ia_logfile << ['reason', headers].flatten


def ia_log(reason, ia_record)
  #$ia_logfile << [reason, ia_record[0..-1]].flatten
  $ia_logfile << [reason, ia_record.to_a].flatten
end

blah = ''
problem_id_exclusion = 0
File.open('hathi_marcxml.xml',"w:UTF-8") do |xml_out|
  xml_out << xml_header
  prev_bnum = nil
  prev_bib = nil
  ifile.each do |ia_record|
    puts ia_record
    ia = IARecord.new(ia_record)
    p ia
    bnum = ia.bib_record_id
    if problem_ids
      if problem_ids.include?(ia.id)
        problem_id_exclusion += 1
        ia_log('on problems.csv', ia_record)
        next
      end
    end
    bib = prev_bnum == bnum ? prev_bib : SierraBib.new(bnum)
    hathi = HathiRecord.new(bib, ia)
    blah = hathi
    puts bnum
    use_old_record = true if prev_bnum == bnum
    prev_bnum = bnum
    prev_bib = bib
    if !hathi.warnings.empty?
      ia_log('no sierra record', ia_record)
    elsif !hathi.ia.ark
      ia_log('no IA ark_id found', ia_record)
    elsif arks.include?(hathi.ia.ark)
      ia_log('record already in HT', ia_record)
    elsif !hathi.manual_write_xml(xml_out)
      ia_log('failed MARC checks', ia_record)
    else
      ia_log('wrote xml', ia_record)
    end
  end
  xml_out << xml_footer
end
$err_log.close
$ia_logfile.close

errors = File.read('bib_errors.txt').split("\n")
if problem_id_exclusion > 0
  errors.insert(0, "na\tExcluded #{problem_id_exclusion} ids of the #{problem_ids.length} ids on problems.csv due to...problems. LDSS, if this count is not what you expected, examine.")
end
File.write('bib_errors.txt', errors.uniq.join("\n"))
