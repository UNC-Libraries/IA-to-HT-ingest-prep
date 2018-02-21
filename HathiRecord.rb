require_relative './IARecord'
require_relative '../sierra_postgres_utilities/SierraBib'

$c.close if $c
$c = Connect.new


class HathiRecord
  attr_reader :oclcnum, :bnum, :warnings, :ia, :hathi_marc, :sierra

  def initialize(sierra_bib, ia_record)
    @warnings = []
    @sierra = sierra_bib
    @bnum = @sierra.bnum
    if @sierra.record_id == nil
      self.warn('No record was found in Sierra for this bnum')
      return
    elsif @sierra.deleted
      self.warn('Sierra bib for this bnum was deleted')
      return
    end
    @marc = @sierra.marc
    @ia = ia_record
    unless @ia.id && @ia.ark
      self.warn('No Ark could be found for this record. Report record to LDSS.')
    end
  end

  def write_oclcnum_to_035?
    oclcnum = @sierra.oclcnum
    return false unless oclcnum
    my035oclcnums = @sierra.marc.get_035oclcnums
    return false if my035oclcnums && my035oclcnums.include?(oclcnum)
    return true
  end

  def my955
    ia_ark = @ia.ark.to_s
    ia_id = @ia.id.to_s
    my955 = MARC::DataField.new('955', ' ', ' ', ['b', ia_ark], ['q', ia_id])
    if @ia.volume
      my955.append(MARC::Subfield.new('v', @ia.volume))
    end
    return my955
  end

  def get_hathi_marc
    hmarc = MARC::Record.new_from_hash(@sierra.marc.to_hash)
    hmarc.fields.delete_if { |f| f.tag =~ /001|003|9../ }
    hmarc.append(MARC::ControlField.new('001', @bnum.chop)) # chop trailing 'a'
    hmarc.append(MARC::ControlField.new('003', 'NcU'))
    if self.write_oclcnum_to_035?
      hmarc.append(MARC::DataField.new('035', ' ', ' ',
          ['a', "(OCoLC)#{@sierra.oclcnum}"]
        ))
    end
    hmarc.append(self.my955)
    sorter = hmarc.to_hash
    sorter['fields'] = sorter['fields'].sort_by { |x| x.keys }
    @hathi_marc = MARC::Record.new_from_hash(sorter)
  end

  def manual_write_xml(open_outfile)
    check_marc
    return unless @warnings.empty?
    xml = open_outfile
    marc = @hathi_marc.to_a
    puts 'writing'
    xml << "<record>\n"
    xml << "  <leader>#{hathi_marc.leader}</leader>\n"
    marc.each do |f|
      if f.tag =~ /00[135678]/
        data = self.escape_xml_reserved(f.value)
        xml << "  <controlfield tag='#{f.tag}'>#{data}</controlfield>\n"
      else
        xml << "  <datafield tag='#{f.tag}' ind1='#{f.indicator1}' ind2='#{f.indicator2}'>\n"
        f.subfields.each do |sf|
          data = self.escape_xml_reserved(sf.value)
          xml << "    <subfield code='#{sf.code}'>#{data}</subfield>\n"
        end
        xml << "  </datafield>\n"
      end
    end
    xml << "</record>\n"
  end  

  def escape_xml_reserved(data)
    return data unless data =~ /[<>&"']/
    data.gsub('&', '&amp;').
         gsub('<', '&lt;').
         gsub('>', '&gt;').
         gsub('"', '&quot;').
         gsub("'", '&apos;')
  end


  def warn(message)
    @warnings << message
    # if given garbage bnum, we want that to display in error
    # log rather than nothing
    bnum = @bnum || @sierra.given_bnum
    puts "#{bnum}\t#{message}\n"
  end

  def check_marc
    self.get_hathi_marc if !@hathi_marc

    # check leader
    if @marc.no_leader?
      warn('This bib record has no Leader. A Leader field is required. Report to cataloging staff to add Leader to record.')      
    end
    if @marc.bad_leader_length?
      warn('Leader is longer or shorter than 24 characters. Report to cataloging staff to fix record.')
    end
    if @marc.ldr06_undefined?
      warn('LDR/06 (rec_type) is an undefined value. Report to cataloging staff to fix record.')
    end
    if @marc.ldr07_undefined?
      warn('LDR/07 (blvl) is an undefined value. Report to cataloging staff to fix record.')
    end
    #todo: if @marc.multiple_leader?
    if @sierra.multiple_LDRs_flag
      warn('This bib record has multiple Leader fields, which should not be. Report to cataloging staff to fix record.')
    end

    # check 001
    if @marc.no_001?
      warn('This bib does not contain an 001 field, which it should have. Report to cataloging staff to fix 001 field.')
    end
    if @marc.multiple_001?
      warn('This bib has more than one 001 field, which is a non-repeatable field. Report to cataloging staff to fix 001 field.')
    end

     # check 003
    if @marc.multiple_003?
      warn('This bib has more than one 003 field, which is a non-repeatable field. Report to cataloging staff to fix 003 field.')
    end

    # check 008
    if @marc.no_008?
      warn('This bib does not contain an 008 field, which is a required field. Report to cataloging staff to fix 008 field.')
    end
    if @marc.multiple_008?
      warn('This bib has more than one 008 field, which is a non-repeatable field. Report to cataloging staff to fix 008 field.')
    end    
    if @marc.bad_008_length?
        warn("This bib's 008 field is not 40 characters long, which it should be. Report to cataloging staff to fix 008 field.")
    end
    unless @sierra.lang008[1]
      # require valid language code, but allow discontinued language codes
      warn("This bib 008/35-37 (language_code) is #{@sierra.lang008[0]} which is not a valid language code. Report to cataloging staff to fix 008 field.")
    end

    # check 245
    if @marc.no_245?
      warn('This bib does not contain an 245 field, which is a required field. Report to cataloging staff to fix 245 field.')
    end
    if @marc.multiple_245?
      warn('This bib has more than one 245 field, which is a non-repeatable field. Report to cataloging staff to fix 245 field.')
    end
    if @marc.no_245_has_ak?
      warn('This bib does not contain an 245 field with a $a or $k, which is a required field. Report to cataloging staff to fix 245 field.')
    end

    # check 300
    if @marc.no_300?
      warn('This bib does not contain an 300 field, which we need for HathiTrust. Report to cataloging staff to fix 300 field.')
    end
    if @marc.m300_without_a?
      warn('This bib contains a 300 without a 300$a, which should not be for HathiTrust. Report to cataloging staff to fix 300 field.')
    end

    # check oclc 035s
    # this needs to be @hathi_marc rather than @marc b/c @marc does not contain
    # 035s we've written from an 001
    if @hathi_marc.no_oclc_035?
      warn('This bib does not contain an 035 field with an OCLC number and does not have an OCLC number in the 001. An OCLC number is required for Hathitrust. Report to cataloging staff.')
    end
    if @hathi_marc.multiple_oclc_035?
      warn('This bib contains multiple 035 fields with OCLC numbers or contains an 035 and an 001 with distinct OCLC numbers. Report to cataloging staff to fix.')
    end
  end

end
