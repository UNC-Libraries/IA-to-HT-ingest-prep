require 'json'
require 'zlib'
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/clean'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

CLEAN.include('problems.csv')
CLEAN.include('new_ia_urls*.mr*')
CLEAN.include('remove_unneeded_ia_urls.*')
CLEAN.include('unneeded_ia_urls.txt')
CLEAN.include('*_ia_log.csv')
CLEAN.include('bib_errors.txt')

CLOBBER.include('search.csv*')
CLOBBER.include('hathi_full*')
CLOBBER.include('nc01.arks.txt')

namespace :download do

  desc 'Download'
  task :all => [:ia, :ht]

  desc 'Download contributions list from IA'
  task :ia => ['download:ia_excludes', 'download:ia_includes']

  desc 'Download/extract most recent hathifile'
  task :ht => ['ht:update']

  desc 'Download IA contributions EXCLUDING ncdhc'
  task :ia_excludes do
    excludes = '"https://archive.org/advancedsearch.php?q=scanningcenter%3A(chapelhill)+AND+unc_bib_record_id%3A%5B*+TO+*%5D+AND+publicdate%3A%5B2001-01-03+TO+null%5D+AND+NOT+collection%3A(ncdhc)+AND+collection%3A(unclibraries)&fl%5B%5D=unc_bib_record_id,identifier,identifier-ark,volume,publicdate,sponsor,contributor,collection&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=5000000&page=1&output=csv&callback=callback&save=yes"'
    sh "curl #{excludes} --silent --output search.csv"
  end

  desc 'Download IA contributions INCLUDING ncdhc'
  task :ia_includes do
    includes = '"https://archive.org/advancedsearch.php?q=scanningcenter%3A(chapelhill)+AND+unc_bib_record_id%3A%5B*+TO+*%5D+AND+publicdate%3A%5B2001-01-03+TO+null%5D+AND+collection%3A(unclibraries)&fl%5B%5D=unc_bib_record_id,identifier,identifier-ark,volume,publicdate,sponsor,contributor,collection&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=5000000&page=1&output=csv&callback=callback&save=yes"'
    sh "curl #{includes} --silent --output search.csv.includes"
  end
end

namespace :ht do
  def most_recent_hathifile
    # this hathi_file_list.json url from "https://www.hathitrust.org/hathifiles"
    file_list_url = 'https://www.hathitrust.org/files/hathifiles/hathi_file_list.json'
    json = JSON.parse(`curl --silent #{file_list_url}`)
    htfile_url = json.select { |f| f['full'] }.
                      sort_by { |f| f['filename'] }.reverse.
                      first['url']
    htfile_name = htfile_url[/hathi_full.*txt/]

    {url: htfile_url, filename: htfile_name}
  end

  desc 'Updates hathifile and arks extract IF outdated'
  task :update do
    most_recent = most_recent_hathifile[:filename]
    if File.exist?(most_recent)
      puts "no hathifile update needed"
    else
      puts "updating hathifile to: #{most_recent}"
      Rake::Task['ht:hathifile:delete'].invoke
      Rake::Task['ht:hathifile:dl'].invoke
      Rake::Task['ht:hathifile:unzip'].invoke
      Rake::Task['ht:extract:arks'].invoke
    end
  end

  namespace :hathifile do
    desc 'Download most recent hathifile'
    task :dl do
      sh "curl -O --silent #{most_recent_hathifile[:url]}"
    end

    desc 'Extract most recent hathifile'
    task :unzip do
      filename = most_recent_hathifile[:filename]
      command = 'gzip -df hathi_full_20*.gz'
      sh command do |ok, _res|
        # Unzip with ruby if gzip not present
        unless ok
          File.open(filename, 'w') do |ofile|
            Zlib::GzipReader.open("#{filename}.gz").each_line do |line|
              ofile.write(line)
            end
          end
          File.delete("#{filename}.gz")
        end
      end
    end

    desc 'Delete existing hathifile(s)'
    task :delete do
      Dir.glob("#{__dir__}/hathi_full_20*txt*").each { |f| File.delete(f) }
    end
  end

  namespace :extract do
    desc 'Extract UNC contributions to nc01.arks.txt'
    task :arks do
      sh 'awk -F\'\t\' \'($1 ~ /^nc01\./) { gsub(/^nc01\./, "", $1); print $1 }\' ' \
        'hathi_full_*.txt > nc01.arks.txt'
    end
  end
end
