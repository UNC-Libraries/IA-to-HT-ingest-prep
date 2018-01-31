require_relative './IARecord'
require_relative './IASierra856'
require_relative '../sierra_postgres_utilities/SierraBib'

$c.close if $c
$c = Connect.new

class SierraBib
  attr_reader :ia

  def ia_ids_in_856u
    my856s = self.m856s
    return nil if !my856s
    archive_856s = my856s.select { |v| v['field_content'] =~ /archive.org/ }
    return nil if !archive_856s
    archive_856u_s = archive_856s.map { |v| subfield_from_field_content('u', v['field_content'])}
    m856_ia_ids = archive_856u_s.map { |sfu|
      m = sfu.match(/details\/(.*)/)
      m ? m[1].strip : []
    }
  end

  # array of ia_ids with this bnum
  def ia_ids
    return nil if !@ia
    return @ia.map { |ia| ia.id }
  end

  def m856s_needed
    if self.serial? && !self.has_query_url
      ia = @ia[0]
      return [IASierra856.new(self, ia).proper_856]
    elsif self.mono?
      needed = self.ia.reject { |ia| self.ia_ids_in_856u.to_a.include?(ia.id)}
      return nil if needed.empty?
      return needed.map { |ia| IASierra856.new(self, ia).proper_856 }
    end
  end

  def ia=(array_of_IA_objects)
    @ia = array_of_IA_objects
  end

  def rec_type
    if ['s', 'b'].include?(self.bcode1_blvl)
      return 'serial'
    elsif ['a', 'c', 'm'].include?(self.bcode1_blvl)
      return 'mono'
    end
  end

  def serial?
    true if self.rec_type == 'serial'
  end

  def mono?
    true if self.rec_type == 'mono'
  end

  def non_IA_856s_w_ind2
    my856s = self.m856s
    return [] if !my856s
    non_IA_856s =
      my856s.select { |v| v['field_content'] !~ /archive.org/ &&
                          v['marc_ind2'] 
      }

  end

  def has_non_IA_856s_w_ind2?
    return true unless self.non_IA_856s_w_ind2.empty?
  end

  def has_query_url
    my856s = self.m856s
    return nil if !my856s
    archive_856s = my856s.select { |v| v['field_content'] =~ /archive.org/ }
    return nil if !archive_856s
    archive_856u_s = archive_856s.map { |v| subfield_from_field_content('u', v['field_content'])}
    archive_856u_s.each do |m856u|
      return true if m856u.match(/unc_bib_record_id.*#{@bnum}/)
    end
  end

  def has_OA_530?
    m530s = self.get_varfields('530') || []
    oca530 = '|aAlso available via the World Wide Web.'
    return true unless m530s.select { |v| v['field_content'] == oca530 }.empty?
  end

  def oca_ebnb_item_count
    query = <<~SQL
      select *
      from sierra_view.bib_record_item_record_link bil
      inner join sierra_view.varfield v on v.record_id = bil.item_record_id
      where bil.bib_record_id = #{@record_id} and v.varfield_type_code = 'j' and
      (v.field_content ilike '%OCA electronic book%' or v.field_content ilike '%OCA electronic journal%')
    SQL
    $c.make_query(query)
    return $c.results.values.length
  end

  def has_oca_ebnb_item?
    return self.oca_ebnb_item_count.length > 0
  end

  def proper_949
    stats_rec_type =
      if self.serial?
        'journal'
      elsif self.mono?
        'book'
      end
    # "\\1" makes the indicators \1
    return "=949  \\1$g1$lebnb$h0$rn$t11$u-$jOCA electronic #{stats_rec_type}"
  end

  def proper_530
    return "=530  \\$aAlso available via the World Wide Web."
  end

  def has_IA_recs_with_dupe_vol?
    return nil if !@ia
  end

  def ia_recs_needing_vol_disambiguation?
    return nil if !@ia
  end

  def ia__recs_lacking_caption
    return nil if !@ia
    return @ia.select { |ia| ia.lacks_caption? }
  end

  def ia_count_by_vol
    hsh = @ia.group_by { |ia| ia.volume }
    hsh.each { |k,v| hsh[k] = v.length }
  end

end
