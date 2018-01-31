require 'csv'

class IARecord
  attr_reader :id, :volume, :ark, :misc, :bib_record_id, :hsh

  def initialize(data_hash)
    @hsh = data_hash
    @id = @hsh[:identifier].to_s.strip
    @volume = @hsh[:volume].to_s.strip
    @ark = @hsh[:"identifier-ark"].to_s.strip
    @bib_record_id = @hsh[:unc_bib_record_id].to_s.strip
  end

  # Reads IA csv exported from advanced search into hash with symbol headers.
  #   The entire line of headers that IA outputs is quoted, so the first
  #   column seems to be named e.g. "unc_record_id,volume,identifier,..." and
  #   everything else is named nil. This fixes that.
  def self.import_search_csv(csv_path)
    ifile = CSV.read(csv_path, headers: true)
    headers = ifile.headers[0].split(",").map { |x| x.to_sym }
    ifile = ifile.to_a[1..-1].map { |row| headers.zip(row).to_h }
    # IA sometimes returns truncated csv's, the last record of which is:
    failstring = 'Search engine returned invalid information or was unresponsive'
    if ifile[-1].values.include?(failstring)
      raise 'The search.csv file is truncated. Re-download it.'
    end
    return ifile
  end

  def lacks_caption
    # don't rely on 0 false positives; add further rules below as needed
    #
    # return true when volume numeration is present and lacks a beginning
    # caption. Years and ordinal numbers are permitted.
    #   each returns false: ['', 'v.3', '1999', '1st thing', '#3']
    #   returns true: '2'
    # permitted date forms:
    # 1867
    # (1867-1968)
    # 1867-1868
    # 1867/1868
    # 1867/68
    # 1867-68
    return false if @volume.empty?
    return false if @volume =~ /^\(?[[:alpha:]]/
    return false if @volume =~ /^\(?[0-9]{4}([^0-9].*)?$/
    return false if @volume =~ /^\(?[0-9]+(st|nd|rd|th|d|er|re|e|eme|de)/
    true
  end

end