require 'fileutils'
require 'csv'

date_str = DateTime.now.strftime('%Y%m%d')

outdir = 'branch_problems'
priority_stem = 'ia_problems'
nopriority_stem = 'no_priority'

Dir.mkdir (outdir) unless Dir.exist?(outdir)
# empty outdir
FileUtils.rm_rf Dir.glob("#{outdir}/*_ia_problems_*.csv")
FileUtils.rm_rf Dir.glob("#{outdir}/*_no_priority_*.csv")

problems = CSV.table('problems.csv')
problems.delete_if { |r| r[:problems].empty? }

headers = problems.headers
headers << :volume
branches = problems.values_at(:branch).flatten.uniq

branches.each do |b|
  my_problems = problems.select { |r| r[:branch] == b}
  if my_problems.select { |r| r[:priority] }.empty?
    stem = nopriority_stem
  else
    stem = priority_stem
  end
  CSV.open("#{outdir}/#{date_str}_#{stem}_#{b}.csv", 'w') do |ofile|
    ofile << headers
    my_problems.each { |row| ofile << row }
  end
end
