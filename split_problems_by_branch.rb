require 'fileutils'
require 'csv'

date_str = DateTime.now.strftime('%Y%m%d')

outdir = 'branch_problems'
Dir.mkdir (outdir) unless Dir.exist?(outdir)
# empty outdir
FileUtils.rm_rf Dir.glob("#{outdir}/*_ia_problems_*.csv")

problems = CSV.table('check_IA_data_for_problems.csv')
problems.delete_if { |r| r[:problems].empty? }

#temp spandr and music exclusions for things being handled outside the branches
exclude = File.read('spandr_music_exclusions.txt').split("\n")
problems.delete_if { |r| exclude.include?(r[:identifier]) }

headers = problems.headers
headers << :volume
branches = problems.values_at(:branch).flatten.uniq

branches.each do |b|
  my_problems = problems.select { |r| r[:branch] == b}
  CSV.open("#{outdir}/#{date_str}_ia_problems_#{b}.csv", 'w') do |ofile|
    ofile << headers
    my_problems.each { |row| ofile << row }
  end
end
