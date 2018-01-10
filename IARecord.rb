class IARecord
  attr_reader :id, :volume, :ark, :misc

  def initialize(ia_identifier, ark_id, volume, misc = nil)
    @id = ia_identifier.to_s.strip
    @volume = volume.to_s.strip
    @ark = ark_id.to_s.strip
    @misc = misc
  end

  def lacks_caption
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
    return false if !@volume
    return false if @volume =~ /^\(?[[:alpha:]]|#/
    return false if @volume =~ /^\(?[0-9]{4}([^0-9].*)?$/
    return false if @volume =~ /^\(?[0-9]+(st|nd|rd|th|d|er|re|e|eme|de)/
    true
    end

end