require_relative './IARecord'
require_relative './IASierra856'
require_relative '../sierra-postgres-utilities/lib/sierra_postgres_utilities.rb'

class SierraBib
  attr_reader :ia

  def ia_ids_in_856u
    return nil if !self.archive_856s
    archive_856u_s = self.archive_856s.map { |v| subfield_from_field_content('u', v[:field_content])}
    m856_ia_ids = archive_856u_s.map { |sfu|
      m = sfu.match(/details\/(.*)/)
      m ? m[1].strip : nil
    }
    m856_ia_ids.compact!
    return nil if m856_ia_ids.empty?
    return m856_ia_ids
  end

  # array of ia_ids with this bnum
  def ia_ids
    return nil if !@ia
    return @ia.map { |ia| ia.id }
  end

  # test
  def m856s_needed
    if self.serial? && !self.has_query_url?
      ia = @ia[0]
      needed = [IASierra856.new(self, ia)]
    elsif self.mono?
      needed = self.ia.reject { |ia| self.ia_ids_in_856u.to_a.include?(ia.id)}
      return nil if needed.empty?
      needed.map! { |ia| IASierra856.new(self, ia) }
    end
    return nil unless needed
    needed.sort_by! { |m856| m856.sortable_sf3 }
    needed.map { |m856| m856.proper_856 }
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

  def relevant_nonIA_856s
    # non-IA 856s with indicators 0 or 1 (link is to resource
    # or version of resource, not something like Table of Contents)
    my856s = self.varfield('856')
    return nil if !my856s
    my856s.select! { |v| v[:field_content] !~ /archive.org/ &&
                          %w(0 1).include?(v[:marc_ind2])
    }
    return nil if my856s.empty?
    my856s
  end

  def archive_856s
    my856s = self.varfield('856')
    return nil if !my856s
    archive_856s = my856s.select { |v| v[:field_content] =~ /archive.org/ }
    return nil if !archive_856s
    return archive_856s
  end

  def has_query_url?
    return false if !self.archive_856s
    archive_856u_s = self.archive_856s.map { |v| subfield_from_field_content('u', v[:field_content])}
    archive_856u_s.each do |m856u|
      return true if m856u.match(/unc_bib_record_id.*#{self.bnum_trunc}/)
    end
    return false
  end

  def has_OA_530?
    m530s = self.varfield('530') || []
    oca530 = '|aAlso available via the World Wide Web.'
    return true unless m530s.select { |v| v[:field_content] == oca530 }.empty?
  end

  def oca_items
    oca_items = self.items&.select { |i| i.is_oca? }
    return nil if oca_items.empty?
    oca_items
  end

  # returns a derived 949 for OCA item creation as a MARC::DataField
  def proper_949(style: :mrk)
    if self.serial?
      item_loc = 'erri'
      stats_rec_type = 'journal'
    elsif self.mono?
      item_loc = 'ebnb'
      stats_rec_type = 'book'
    end
    m949 = MARC::DataField.new('949', ' ', '1',
      ['g', '1'],
      ['l', item_loc],
      ['h', '0'],
      ['r', 'n'],
      ['t', '11'],
      ['u', '-'],
      ['j', "OCA electronic #{stats_rec_type}"]
    )
  end

  # returns the standard 530 for OCA bibs as a MARC::DataField
  def proper_530
    field_content = "Also available via the World Wide Web."
    m530 = MARC::DataField.new('530', ' ', ' ', ['a', field_content])
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
