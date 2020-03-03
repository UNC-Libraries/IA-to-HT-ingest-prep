module IaToHtIngestPrep
  # Checks an IA item/record and its corresponding Sierra Bib to identify/triage
  # IA metadata problems.
  class IaItemChecker
    attr_reader :bib, :ia
    attr_accessor :in_ht

    def initialize(bib, ia)
      @bib = bib
      @ia = ia
    end

    # priority 1 - things not in HT
    # priority 2 - things in HT, except the below
    # priority 3 - serials in HT that only need captions
    # priority nil - anything that doesn't itself need fixing
    def priority
      return nil unless needs_fix?
      return 1 unless in_ht
      return 3 if notes == ['CAPTION:this IA serial lacks caption']
      2
    end

    def link_in_sierra?
      return false if bib.invalid? || bib.deleted?
      return true if bib.serial? && bib.has_query_url?
      return true if bib.mono? && bib.ia_ids_in_856u.to_a.include?(ia.id)
      false
    end

    # serial captions only affect HT/IA not Sierra links
    # mono captions affect HT/IA and Sierra links
    # if a serial is already in HT, lacks caption is not so big a problem,
    # but monos already in HT still need captions for proper Sierra links.
    def lacks_caption?
      ia.lacks_caption?
    end

    # if bib has any ia with vol info that lacks caption
    # may as well warn about any on bib, such that with "v.2" and "2"
    # we'll reject both and process as dupes, rather than permit the "v.2"
    # and later find the "2" is a dupe
    def other_item_lacks_caption?
      !lacks_caption? && bib.ia_items.select { |ia| ia.lacks_caption? }.any?
    end

    # ia has no vol info but bib is mvmono or serial
    def needs_volume?
      !ia.volume && ( bib.ia_items.length > 1 || (!bib.deleted? && bib.serial?))
    end

    # not needs_volume? and bib.has multiple recs and >0 recs lack volume data
    def other_item_needs_volume_disambiguation?
      !needs_volume? && bib.ia_count_by_vol[nil] &&
        (bib.ia_count_by_vol[nil] > 1 || bib.ia_count_by_vol.length > 1)
    end

    # ia has other rec in ia with same vol info (and vol info exists)
    def duplicate_volume?
      ia.volume && bib.ia_count_by_vol[ia.volume] > 1
    end

    def notes
      return @notes if @notes

      notes = []
      if bib.invalid? || bib.deleted?
        notes <<
          if bib.invalid?
            'invalid bib_record_id'
          else
            'bib deleted'
          end
        return notes
      end

      notes << 'bib suppressed' if bib.suppressed?

      notes << "CAPTION:this IA #{bib.ia_rec_type} lacks caption" if lacks_caption?
      notes << 'other IA item on bib lacks caption' if other_item_lacks_caption?
      notes << 'DISAMBIGUATE:this IA item needs volume' if needs_volume?

      if other_item_needs_volume_disambiguation?
        notes << 'other IA items on bib need volume disambiguation'
      end

      notes << 'DUPE?: bib has >1 IA item with this volume' if duplicate_volume?

      @notes = notes
    end

    def needs_fix?
      bib.invalid? || lacks_caption? || needs_volume? || duplicate_volume?
    end

    def problems?
      notes.any?
    end

    def output_row
      [
        ia.id,
        "https://archive.org/details/#{ia.id}",
        priority,
        notes.join(';;;'),
        bib.bnum,
        ia.bib_record_id,
        ia.volume,
        bib.ia_items.length.to_s,
        in_ht,
        link_in_sierra?,
        bib.not_in_ht_item_count.to_s,
        ia.ark,
        ia.hsh[:publicdate].to_s,
        ia.hsh[:sponsor].to_s,
        ia.hsh[:contributor].to_s,
        ia.hsh[:collection].to_s,
        ia.branch
      ]
    end
  end
end
