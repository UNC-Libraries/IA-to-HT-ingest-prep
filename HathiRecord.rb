require_relative './IARecord'
require_relative '../sierra-postgres-utilities/lib/sierra_postgres_utilities'


class HathiRecord < DerivativeRecord
  attr_reader :ia

  def initialize(sierra_bib, ia_record)
    super(sierra_bib)
    @ia = ia_record
    unless @ia.id && @ia.ark
      warn('No Ark could be found for this record. Report record to LDSS.')
    end
  end

  def my955
    m955 = MARC::DataField.new('955', ' ', ' ')
    m955.add_subfields!('b', @ia.ark)
    m955.add_subfields!('q', @ia.id)
    m955.add_subfields!('v', @ia.volume)
    return nil if m955.subfields.empty?
    m955
  end

  def check_marc

    # check leader
    if @smarc.no_leader?
      warn('This bib record has no Leader. A Leader field is required. Report to cataloging staff to add Leader to record.')
    end
    if @smarc.bad_leader_length?
      warn('Leader is longer or shorter than 24 characters. Report to cataloging staff to fix record.')
    end
    if @smarc.ldr06_invalid?
      warn('Invalid LDR/06 (rec_type). It is an undefined value or not present. Report to cataloging staff to fix record.')
    end
    if @smarc.ldr07_invalid?
      warn('Invalid LDR/07 (blvl). It is an undefined value or not present. Report to cataloging staff to fix record.')
    end
    #todo: if @marc.multiple_leader?
    if @sierra.multiple_LDRs_flag
      warn('This bib record has multiple Leader fields, which should not be. Report to cataloging staff to fix record.')
    end

    # check 001
    if @smarc.count('001') == 0
      warn('This bib does not contain an 001 field, which it should have. Report to cataloging staff to fix 001 field.')
    end
    if @smarc.count('001') >= 2
      warn('This bib has more than one 001 field, which is a non-repeatable field. Report to cataloging staff to fix 001 field.')
    end

     # check 003
    if @smarc.count('003') >= 2
      warn('This bib has more than one 003 field, which is a non-repeatable field. Report to cataloging staff to fix 003 field.')
    end

    # check 008
    if @smarc.count('008') == 0
      warn('This bib does not contain an 008 field, which is a required field. Report to cataloging staff to fix 008 field.')
    end
    if @smarc.count('008') >= 2
      warn('This bib has more than one 008 field, which is a non-repeatable field. Report to cataloging staff to fix 008 field.')
    end
    if @smarc.bad_008_length?
        warn("This bib's 008 field is not 40 characters long, which it should be. Report to cataloging staff to fix 008 field.")
    end
    unless @sierra.lang008[1]
      # require valid language code, but allow discontinued language codes
      warn("This bib 008/35-37 (language_code) is #{@sierra.lang008[0]} which is not a valid language code. Report to cataloging staff to fix 008 field.")
    end

    # check 245
    if @smarc.count('245') == 0
      warn('This bib does not contain an 245 field, which is a required field. Report to cataloging staff to fix 245 field.')
    end
    if @smarc.count('245') >= 2
      warn('This bib has more than one 245 field, which is a non-repeatable field. Report to cataloging staff to fix 245 field.')
    end
    if @smarc.no_245_has_ak?
      warn('This bib does not contain an 245 field with a $a or $k, which is a required field. Report to cataloging staff to fix 245 field.')
    end

    # check 300
    if @smarc.count('300') == 0 && @sierra.blvl !~ /b|i|s/
      warn('This mono bib does not contain an 300 field, which we need for HathiTrust. Report to cataloging staff to fix 300 field.')
    end
    if @smarc.m300_without_a? && @sierra.blvl !~ /b|i|s/
      warn('This mono bib contains a 300 without a 300$a, which should not be for HathiTrust. Report to cataloging staff to fix 300 field.')
    end

    # check oclc 035s
    # this needs to be @altmarc rather than @smarc b/c @smarc does not contain
    # 035s we've written from an 001
    if altmarc.oclc_035_count == 0
      warn('This bib does not contain an 035 field with an OCLC number and does not have an OCLC number in the 001. An OCLC number is required for Hathitrust. Report to cataloging staff.')
    end
    if altmarc.oclc_035_count >= 2
      warn('This bib contains multiple 035 fields with OCLC numbers or contains an 035 and an 001 with distinct OCLC numbers. Report to cataloging staff to fix.')
    end
  end

end
