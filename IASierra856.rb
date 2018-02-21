

class IASierra856

  def initialize(bib, ia)
    @bib = bib
    @ia = ia
    @bnum = @bib.bnum
    @ia_id = @ia.id
    @serial = @bib.serial?
    @mono = @bib.mono?
    @mat_type = @bib.mat_type

  end

  def proper_sfu
    if @serial
      bib_rec_id = @ia.bib_record_id
      return nil unless bib_rec_id
      return "|uhttps://archive.org/search.php?sort=publicdate&query=scanningcenter%3Achapelhill+AND+mediatype%3Atexts+AND+unc_bib_record_id%3A#{bib_rec_id}"
    elsif @mono
      return nil unless @ia_id
      return "|uhttps://archive.org/details/#{@ia_id}"
    end
  end

  def proper_sfy
    return '|yFull text available via the UNC-Chapel Hill Libraries'
  end

  def proper_sf3
    if @bib.relevant_nonIA_856s
      prefix = 'Internet Archive'
    else
      prefix = ''
    end
    if @serial
      content = prefix
    elsif @mono
      if @ia.volume == nil
        content = prefix
      elsif !prefix.empty?
        content = "#{prefix}, #{@ia.volume}"
      else
        content = @ia.volume
      end
    end
    return "|3#{content}" unless content.empty?
    return ''
  end

  def proper_856_content
    return nil if !self.proper_sfu
    self.proper_sf3.to_s + self.proper_sfu + self.proper_sfy
  end

  def proper_ind2
    #based on mat_type
    if %w(z s w m).include?(@mat_type)
      return '0'
    else
      return '1'
    end
  end

  def proper_856
    return nil if !self.proper_856_content
    ind2 = self.proper_ind2
    return "=856  4#{ind2}#{self.proper_856_content}"
  end


end