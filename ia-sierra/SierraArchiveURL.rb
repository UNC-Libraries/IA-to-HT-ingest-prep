require_relative '../IASierraBib'


class SierraArchiveURL
  attr_reader :bnum, :mat_type, :ia_id, :sfu, :sf3, :sfx, :sfy,
    :oca_stats_count, :ind2, :bib, :proper
  attr_accessor :ia, :notes

  def initialize(hsh, bib: nil)
    @bnum = hsh['bnum']
    @bib = bib || IASierraBib.new(@bnum)
    @notes = []
    @sfu = hsh['sfu'].to_s
    @sf3 = hsh['sf3'].to_s
    @sfx = hsh['sfx'].to_s
    @sfy = hsh['sfy'].to_s
    @ind2 = hsh['ind2'].to_s
    @url = hsh['field_content'].to_s
    @serial = bib.serial?
    @mono = bib.mono?
    @oca_stats_count = bib.oca_ebnb_item_count
    self.ia_id
  end

  def ia=(ia_record)
    @ia = ia_record
  end

  def proper
    @proper ||= self.get_proper
  end

  def get_proper
    return nil unless @ia
    IASierra856.new(@bib, @ia)
  end

  def has_no_archive_856u?
    unless @sfu =~ /archive\.org/
      @notes << 'no archive.org url in 856$u'
      return true
    end
  end

  def sierra_856_perfect?
    @url == self.proper.proper_856_content
  end

  def ia_id
    @ia_id ||= self.get_ia_id
  end

  def get_ia_id
    m = @sfu.match(/details\/(.*)/)
    unless m
      @ia_id = nil
      return
    end
    @ia_id = m[1].strip
  end

  def url_call_number
    @url_call_number ||= self.get_url_call_number
  end

  def get_url_call_number
    m = @sfu.match(/call_number[^b]*(b[0-9]*)/)
    unless m
      @url_call_number = nil
      return
    end
    @url_call_number = m[1].strip
  end

  def url_bib_record_id
    @url_bib_record_id ||= self.get_url_bib_record_id
  end

  def get_url_bib_record_id
    self.get_url_call_number if !@url_call_number
    @url_bib_record_id =  @url_call_number[0..7] if @url_call_number
  end

  def check_ia_record_found
    #do we find the ia_id or bib_record id in UNC IA data?
  end

  def urls_sierra_bib_should_have(array_of_ia_recs)
    return nil unless array_of_ia_recs
    return @serial ? 1 : array_of_ia_recs.length
  end

  def do_checks
    if self.mono_has_query_url?
      @sfu, @sfx = @sfx, @sfu
      @sfx = nil if @sfx.empty?
    end
    self.serial_has_sf3_content?
    self.serial_has_detail_url?
    self.mono_id_not_found_in_IA?
    self.mono_sf3_empty_IA_vol_populated?
    self.mono_has_sf3_not_matching_IA_vol?
    self.has_non_standard_856y?
    self.has_856x?
    self.non_orig_print_rec_with_print_mat_type
    self.ind2_conflict?
    return true if @notes.empty?
  end


  def serial_has_sf3_content?
    return nil unless @serial
    unless @sf3.empty?
      @notes << 'serial has sf3 content'
      return true
    end
  end

  def serial_has_detail_url?
    if @serial && @ia_id
      @notes << 'serial has detail url'
      return true
    end
  end

  def mono_id_not_found_in_IA?
    if @mono && @ia_id && !ia
      @notes << 'mono id not found in IA'
      return true
    end
  end


  def mono_sf3_empty_IA_vol_populated?
    return nil if !ia
    if @mono && @sf3.empty? && !@ia.volume.empty?
      @notes << 'mono url has no sf3 but IA has vol info'
      return true
    end
  end

  def mono_has_sf3_not_matching_IA_vol?
    return nil if !ia
    if @mono && !@sf3.empty? && "|3#{@sf3}" != @ia.volume
      @notes << 'mono url has sf3 that does not match IA vol'
      return true
    end
  end

  def mono_has_query_url?
    if @mono && !@ia_id
      @notes << 'mono has query url'
      return true
    end
  end

  def is_orig_print_rec?
    short_bnum = @bib.trunc_bnum
    if self.url_bib_record_id == short_bnum || (@ia && @ia.bib_record_id == short_bnum)
      return true
    else
      return false
    end
  end

  def have_jurisdiction?
    return true if self.is_orig_print_rec? || oca_stats_count != '0'
  end

  # sierra bibs that are original print records should have an entry
  # as a unc_bib_record_id
  # sierra bibs w/ OCA stats item that are not original print records should
  # be derived electronic records
  # If these not-original print records have mat types not in (z, s, w)
  # that's weird. Some seem to be wrong actual-print record got tagged
  # with an ia_identifier. Some seem to be electronic derived records
  # given the wrong mat_type
  def non_orig_print_rec_with_print_mat_type
    if (self.have_jurisdiction? && !self.is_orig_print_rec? &&
              !['z', 's', 'w'].include?(@bib.mat_type)
    )
      @notes << 'mat_type does not match orig_print_rec-ness'
      return true
    end
  end


  def has_non_standard_856y?
    if "|y#{@sfy}" != self.proper.proper_sfy
      notes << 'has non-standard 856$y'
      return true
    end
  end

  def has_856x?
    unless @sfx.empty?
      @notes << 'has populated 856$x'
      return true
    end
  end

  def ind2_conflict?
    if @ind2 != self.proper.proper_ind2
      @notes << 'actual ind2 conflicts with mat_type'
      return true
    end
  end

  def proper_bib_record_id
    if @serial
      return nil if !url_bib_record_id && !ia
      url_bib_record_id ? url_bib_record_id : ia.bib_record_id
    end
  end

  def all_proper_856s(array_of_ia_recs)
    # only for orig print records
    return nil if !array_of_ia_recs || array_of_ia_recs.empty?
    return [self.proper.proper_856] if @serial
    return nil unless @mono
    bib_id = self.url_bib_record_id || @bib.trunc_bnum
    proper_856s = []
    array_of_ia_recs.each do |ia|
      proper_856s << IASierra856.new(@bib, ia).proper_856
    end
    return proper_856s.sort.join(';;;')
  end

end

