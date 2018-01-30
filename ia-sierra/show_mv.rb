require 'csv'
require_relative '../HathiRecord.rb'


ifile = CSV.read('search.csv', headers: true) # bnum, id, ark, vol
ifile = ifile.sort_by { |r| r[0] }

bnums = {}
ifile.each do |ia_record|
  bnum, ia_id, ark, volume, *misc = ia_record[0..-1]
  if bnums.include?(bnum)
    bnums[bnum] << ia_record
  else
    bnums[bnum] = [ia_record]
  end
end

bnums.keep_if { |k,v| v.length > 1 }
bnums.delete_if { |k,v| v.select { |x| x[3] == '' }.empty? }


CSV.open('mv_lacking_volume.csv', 'w') do |csv|
  bibs = bnums.values
  bibs.each { |entries| entries.sort_by! { |e| e[3].to_s } }
  bibs.flatten.each { |row| csv << row }
end