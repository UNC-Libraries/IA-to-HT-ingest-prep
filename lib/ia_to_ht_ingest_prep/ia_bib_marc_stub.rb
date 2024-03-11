module IaToHtIngestPrep
  # A standard MARC stub (e.g. 907, 944 batch load note, etc.) that also
  # includes needed 856s, and 530/949 fields as appropriate.
  class IaBibMarcStub
    def initialize(ia_bib)
      @ia_bib = ia_bib
      @sierra_stub = ia_bib.marc_stub
      @is_erec = ia_bib.erec?
      @serial_or_mono = case
                        when ia_bib.serial?
                          then :serial
                        when ia_bib.mono?
                          then :mono
                        end
      @oca_items_exist = ia_bib.oca_items&.any?
    end

    def stub(m856s)
      stub = @sierra_stub
      stub << proper_530 if lacking?(proper_530)

      stub << proper_599 if lacking?(proper_599)
      stub << proper_773 if lacking?(proper_773)

      m856s.each { |m856| stub << m856 }
      stub << proper_949 unless @oca_items_exist

      stub.sort
    end

    private

    # True when bib lacks a given field
    def lacking?(field)
      return false unless field

      @ia_bib.marc.fields.find { |f| f == field }.nil?
    end

    def proper_530
      self.class.proper_530(is_erec: @is_erec)
    end

    def proper_599
      self.class.proper_599
    end

    def proper_773
      self.class.proper_773
    end

    def proper_949
      self.class.proper_949(@serial_or_mono)
    end

    # returns the standard 530 for OCA bibs as a MARC::DataField
    # nil for e-records (which don't need a 530)
    def self.proper_530(is_erec:)
      return if is_erec

      field_content = "Also available via the World Wide Web."
      MARC::DataField.new('530', ' ', ' ', ['a', field_content])
    end

    def self.proper_599
      MARC::DataField.new('599', ' ', ' ', ['a', 'LTIEXP'])
    end

    def self.proper_773
      MARC::DataField.new('773', '0', ' ', ['t', 'Digitized by UNC Chapel Hill'])
    end

    # returns a derived 949 for OCA item creation as a MARC::DataField
    def self.proper_949(record_type)
      if record_type == :serial
        item_loc = 'erri'
        stats_rec_type = 'journal'
      elsif record_type == :mono
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
