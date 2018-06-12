

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
      return MARC::Subfield.new('u', self.query_url(bib_rec_id))
    elsif @mono
      return nil unless @ia_id
      return MARC::Subfield.new('u', "https://archive.org/details/#{@ia_id}")
    end
  end

  def query_url(bib_record_id)
    "https://archive.org/search.php?sort=publicdate&query=scanningcenter%3Achapelhill+AND+mediatype%3Atexts+AND+unc_bib_record_id%3A#{bib_record_id}"
  end

  def proper_sfy
    return MARC::Subfield.new('y', "Full text available via the UNC-Chapel Hill Libraries")
  end

  def proper_sfx
    return MARC::Subfield.new('x', "ocalink_ldss")
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
    return nil if content.empty?
    return MARC::Subfield.new('3', content)
  end

  def proper_856_content
    content = self.proper_856
    return nil unless content
    content.gsub(/^856  4./, '')
  end

  def proper_ind2
    #based on mat_type
    if %w(z s w m).include?(@mat_type)
      return '0'
    else
      return '1'
    end
  end

  def sortable_sf3
    sf3 = self.proper_sf3
    return '' unless sf3
    sf3 = sf3.value
    sf3.to_s.gsub(/([0-9]+)/) do |m|
      $1.rjust(10, '0')
    end
  end

  def proper_856
    return nil unless self.proper_sfu
    ind2 = self.proper_ind2
    m856 = MARC::DataField.new('856', '4', ind2)
    if self.proper_sf3
      m856.append(self.proper_sf3)
    end
    m856.append(self.proper_sfu)
    m856.append(self.proper_sfy)
    m856.append(self.proper_sfx)
    m856
  end
end