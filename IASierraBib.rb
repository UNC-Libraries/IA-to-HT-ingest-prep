require_relative './IARecord'
require_relative './IASierra856'
require_relative '../sierra-postgres-utilities/lib/sierra_postgres_utilities.rb'

class SierraBib
  attr_reader :ia

  def ia_ids_in_856u
    return nil unless archive_856s
    m856u = marc.field_find_all(tag: '856', complex_subfields: [
      [:has_as_first, code: 'u', value: /details\//]
    ]).map { |f| f['u'] }
    ids = m856u.map { |sf| sf.match(/details\/(.*)/)[1].strip }
    return nil if ids.empty?
    ids
  end

  # array of ia_ids with this bnum
  def ia_ids
    return nil if !@ia
    return @ia.map { |ia| ia.id }
  end

  # test
  def m856s_needed
    if serial? && !has_query_url?
      ia = @ia[0]
      needed = [IASierra856.new(self, ia)]
    elsif mono?
      needed = @ia.reject { |ia| ia_ids_in_856u.to_a.include?(ia.id)}
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

  def ia_rec_type
    if ['s', 'b'].include?(bcode1_blvl)
      return 'serial'
    elsif ['a', 'c', 'm'].include?(bcode1_blvl)
      return 'mono'
    end
  end

  def serial?
    true if ia_rec_type == 'serial'
  end

  def mono?
    true if ia_rec_type == 'mono'
  end

  def relevant_nonIA_856s
    # non-IA 856s with indicators 0 or 1 (link is to resource
    # or version of resource, not something like Table of Contents)
    relevant_856s = marc.field_find_all(tag: '856', ind2: /0|1/,
                                         value_not: /archive.org/ )
    return nil if relevant_856s.empty?
    relevant_856s
  end

  def archive_856s
    archive_856s = marc.field_find_all(tag: '856', value: /archive.org/ )
    return nil if archive_856s.empty?
    archive_856s
  end

  def has_query_url?
    return false unless archive_856s
    marc.any_fields?(tag: '856', complex_subfields: [
      [:has, code: 'u', value:  /unc_bib_record_id.*#{bnum_trunc}/]
    ])
  end

  # deprecate in favor of lacking_oca_530?
  def has_OA_530?
    oca530 = '|aAlso available via the World Wide Web.'
    marc.fields('530').select { |f| f.field_content == oca530 }.any?
  end

  # True when bib has no OCA 530 and needs one (i.e. not an e-record).
  def lacking_oca_530?
    return false if %w(z s w m).include?(mat_type)
    oca530 = '|aAlso available via the World Wide Web.'
    marc.fields('530').select { |f| f.field_content == oca530 }.empty?
  end

  def oca_items
    oca_items = items&.select { |i| i.is_oca? }
    return nil if oca_items.empty?
    oca_items
  end

  # returns a derived 949 for OCA item creation as a MARC::DataField
  def proper_949
    if serial?
      item_loc = 'erri'
      stats_rec_type = 'journal'
    elsif mono?
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
  # nil for e-records (which don't need a 530)
  def proper_530
    return nil if %w(z s w m).include?(mat_type)
    field_content = "Also available via the World Wide Web."
    m530 = MARC::DataField.new('530', ' ', ' ', ['a', field_content])
  end

  # todo; or discard
  def has_IA_recs_with_dupe_vol?
    return nil if !@ia
  end

  # todo; or discard
  def ia_recs_needing_vol_disambiguation?
    return nil if !@ia
  end


  def ia_recs_lacking_caption
    return nil if !@ia
    @ia.select { |ia| ia.lacks_caption? }
  end

  def ia_count_by_vol
    hsh = @ia.group_by { |ia| ia.volume }
    hsh.each { |k,v| hsh[k] = v.length }
  end

end
