module IaToHtIngestPrep
  # A standard MARC stub (e.g. 907, 944 batch load note, etc.) that also
  # includes needed 856s, and 530/949 fields as appropriate.
  class IaBibMarcStub
    attr_reader :ia_bib

    def initialize(ia_bib)
      @ia_bib = ia_bib
    end

    def stub(m856s)
      stub = ia_bib.sierra.stub
      stub << proper_530 if lacking_oca_530?

      m856s.each { |m856| stub << m856 }
      stub << proper_949 unless ia_bib.oca_items&.any?

      stub.sort
    end

    # True when bib has no OCA 530 and needs one (i.e. not an e-record).
    def lacking_oca_530?
      return false unless proper_530

      ia_bib.marc.fields.find { |f| f == proper_530 }.nil?
    end

    def proper_530
      self.class.proper_530(ia_bib)
    end

    def proper_949
      self.class.proper_949(ia_bib)
    end

    # returns the standard 530 for OCA bibs as a MARC::DataField
    # nil for e-records (which don't need a 530)
    def self.proper_530(bib)
      return if bib.erec?

      field_content = "Also available via the World Wide Web."
      MARC::DataField.new('530', ' ', ' ', ['a', field_content])
    end

    # returns a derived 949 for OCA item creation as a MARC::DataField
    def self.proper_949(bib)
      if bib.serial?
        item_loc = 'erri'
        stats_rec_type = 'journal'
      elsif bib.mono?
        item_loc = 'ebnb'
        stats_rec_type = 'book'
      end

      MARC::DataField.new('949', ' ', '1',
        ['g', '1'],
        ['l', item_loc],
        ['h', '0'],
        ['r', 'n'],
        ['t', '11'],
        ['u', '-'],
        ['j', "OCA electronic #{stats_rec_type}"]
      )
    end
  end
end
