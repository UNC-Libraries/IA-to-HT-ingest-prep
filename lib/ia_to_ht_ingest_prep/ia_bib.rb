module IaToHtIngestPrep
  # A Sierra Bib record with supplemental logic relevant to IA
  class IaBib
    attr_reader :sierra
    attr_accessor :ia_items, :not_in_ht_item_count

    def initialize(sierra_bib)
      @sierra = sierra_bib
      @ia_items = []
    end

    def bnum
      return "b#{sierra.record_num}a" if deleted?
      @sierra.bnum
    end

    def bnum_trunc
      @sierra.bnum_trunc
    end

    def deleted?
      @sierra.deleted?
    end

    def suppressed?
      @sierra.suppressed?
    end

    def invalid?
      !@sierra
    end

    def mat_type
      @sierra.mat_type
    end

    def marc
      @sierra.marc
    end

    def marc_stub
      @sierra.stub
    end

    # Bib rec type in the context of IA
    def ia_rec_type
      case @sierra.bcode1
      when 's', 'b'
        'serial'
      when 'a', 'c', 'm'
        'mono'
      end
    end

    def serial?
      ia_rec_type == 'serial'
    end

    def mono?
      ia_rec_type == 'mono'
    end

    def erec?
      %w(z s w m).include?(mat_type)
    end

    # array of ia_ids with this bnum
    def ia_ids
      return nil if !@ia
      @ia.map(&:id)
    end

    # count of ia items by volume
    def ia_count_by_vol
      @ia_count_by_vol ||=
        @ia_items.group_by { |ia| ia.volume }.map { |k,v| [k, v.length] }.to_h
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

    def ia_ids_in_856u
      return nil unless archive_856s
      m856u = marc.field_find_all(tag: '856', complex_subfields: [
        [:has_as_first, code: 'u', value: /details\//]
      ]).map { |f| f['u'] }
      ids = m856u.map { |sf| sf.match(/details\/(.*)/)[1].strip }
      return nil if ids.empty?
      ids
    end

    def m856s_needed
      if serial? && !has_query_url?
        ia = ia_items.first
        needed = [IASierra856.new(self, ia)]
      elsif mono?
        needed = ia_items.reject { |i| ia_ids_in_856u.to_a.include?(i.id)}
        return nil if needed.empty?
        needed.map! { |i| IASierra856.new(self, i) }
      end
      return nil unless needed
      needed.sort_by! { |m856| m856.sortable_sf3 }
      needed.map { |m856| m856.proper_856 }
    end

    def oca_items
      oca_items = sierra.items&.select { |i| i.oca? }
      return nil if oca_items.empty?
      oca_items
    end
  end
end
