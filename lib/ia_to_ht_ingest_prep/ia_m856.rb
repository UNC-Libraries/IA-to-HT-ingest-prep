
module IaToHtIngestPrep
  # Represents a correct/proper 856 for a given bib:ia_item pair (in contrast
  # to SierraArchiveURL which represents an actual 856 in Sierra).
  class IASierra856
    attr_reader :bib, :ia

    def initialize(bib, ia)
      @bib = bib
      @ia = ia
    end

    def proper_sfu
      if bib.serial?
        bib_rec_id = ia.bib_record_id
        return unless bib_rec_id

        MARC::Subfield.new('u', query_url(bib_rec_id))
      elsif bib.mono?
        return unless ia.id

        MARC::Subfield.new('u', "https://archive.org/details/#{ia.id}")
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

    def relevant_nonIA_856s?
      true if self.class.relevant_nonIA_856s(bib)
    end

    def self.relevant_nonIA_856s(bib)
      # non-IA 856s with indicators 0 or 1 (link is to resource
      # or version of resource, not something like Table of Contents)
      relevant_856s = bib.marc.field_find_all(tag: '856', ind2: /0|1/,
                                           value_not: /archive.org/ )
      return nil if relevant_856s.empty?
      relevant_856s
    end

    def proper_sf3
      if relevant_nonIA_856s?
        prefix = 'Internet Archive'
      else
        prefix = ''
      end
      if bib.serial?
        content = prefix
      elsif bib.mono?
        if ia.volume == nil
          content = prefix
        elsif !prefix.empty?
          content = "#{prefix}, #{ia.volume}"
        else
          content = ia.volume
        end
      end
      return if content.empty?

      MARC::Subfield.new('3', content)
    end

    def proper_856_content
      proper_856&.gsub(/^856  4./, '')
    end

    def proper_ind2
      return '0' if bib.erec?
      '1'
    end

    def sortable_sf3
      sf3 = proper_sf3
      return '' unless sf3
      sf3 = sf3.value
      sf3.to_s.gsub(/([0-9]+)/) do |m|
        $1.rjust(10, '0')
      end
    end

    def proper_856
      return nil unless proper_sfu
      ind2 = proper_ind2
      m856 = MARC::DataField.new('856', '4', ind2)
      m856.append(proper_sf3) if proper_sf3
      m856.append(proper_sfu)
      m856.append(proper_sfy)
      m856.append(proper_sfx)
      m856
    end
  end
end
