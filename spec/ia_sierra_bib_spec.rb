require 'spec_helper'

module IaToHtIngestPrep
  RSpec.describe IaBib do
    def marc_record(*fields)
      MARC::Record.new.tap do |record|
        fields.each { |field| record.append(field) }
      end
    end

    def sierra_bib(bcode1:, marc: MARC::Record.new, items: [], mat_type: 'a')
      double(
        bcode1: bcode1,
        bnum_trunc: 'b2095036',
        items: items,
        marc: marc,
        mat_type: mat_type
      )
    end

    def ia_record(overrides = {})
      IaRecord.new({
        :unc_bib_record_id => 'b2095036',
        :identifier => 'elclavoardiendod550valc',
        :'identifier-ark' => 'ark:/13960/t9962ss6m',
        :volume => 'v.3'
      }.merge(overrides))
    end

    describe '#oca_items' do
      it 'includes OCA items' do
        items = [double(oca?: true, inum: 'i10105652a')]
        bib = described_class.new(sierra_bib(bcode1: 'a', items: items))

        expect(bib.oca_items.map(&:inum)).to eq(['i10105652a'])
      end

      it 'excludes non-OCA items' do
        items = [
          double(oca?: true, inum: 'i10105652a'),
          double(oca?: false, inum: 'i10105653a')
        ]
        bib = described_class.new(sierra_bib(bcode1: 'a', items: items))

        expect(bib.oca_items.map(&:inum)).to eq(['i10105652a'])
      end

      it 'returns nil when there are no OCA items' do
        items = [double(oca?: false, inum: 'i10105653a')]
        bib = described_class.new(sierra_bib(bcode1: 'a', items: items))

        expect(bib.oca_items).to be_nil
      end
    end

    describe '#ia_rec_type' do
      { 's' => 'serial', 'b' => 'serial',
        'a' => 'mono', 'c' => 'mono', 'm' => 'mono' }.each do |bcode1, type|
        it "is #{type} when bcode1 is #{bcode1.inspect}" do
          bib = described_class.new(sierra_bib(bcode1: bcode1))

          expect(bib.ia_rec_type).to eq(type)
        end
      end
    end

    describe '#has_query_url?' do
      it 'is true if a matching query URL is present in an 856$u' do
        query = MARC::DataField.new(
          '856', '4', '1',
          ['u', 'https://archive.org/search.php?query=unc_bib_record_id%3Ab2095036']
        )
        bib = described_class.new(
          sierra_bib(bcode1: 's', marc: marc_record(query))
        )

        expect(bib.has_query_url?).to be true
      end

      it 'is false if no matching query URL is present' do
        detail = MARC::DataField.new('856', '4', '1', ['u', 'https://archive.org/details/foo'])
        bib = described_class.new(
          sierra_bib(bcode1: 's', marc: marc_record(detail))
        )

        expect(bib.has_query_url?).to be false
      end
    end

    describe '#ia_ids_in_856u' do
      it 'returns identifiers from archive.org detail URLs' do
        first_detail = MARC::DataField.new(
          '856', '4', '1',
          ['u', 'https://archive.org/details/londonlabourlond01mayh']
        )
        second_detail = MARC::DataField.new(
          '856', '4', '1',
          ['u', 'https://archive.org/details/londonlabourlond02mayh_0']
        )
        bib = described_class.new(
          sierra_bib(bcode1: 's', marc: marc_record(first_detail, second_detail))
        )

        expect(bib.ia_ids_in_856u).to eq(
          ['londonlabourlond01mayh', 'londonlabourlond02mayh_0']
        )
      end

      it 'returns nil if no detail URLs are present' do
        query = MARC::DataField.new(
          '856', '4', '1',
          ['u', 'https://archive.org/search.php?query=unc_bib_record_id%3Ab2095036']
        )
        bib = described_class.new(
          sierra_bib(bcode1: 's', marc: marc_record(query))
        )

        expect(bib.ia_ids_in_856u).to be_nil
      end
    end

    describe '#m856s_needed' do
      it 'returns a query 856 for serials lacking a query URL' do
        bib = described_class.new(sierra_bib(bcode1: 's'))
        bib.ia_items = [ia_record]

        expect(bib.m856s_needed.map(&:to_mrk)).to eq([
          '=856  41$uhttps://archive.org/search.php?sort=publicdate&query=' \
          'scanningcenter%3Achapelhill+AND+mediatype%3Atexts+AND+' \
          'unc_bib_record_id%3Ab2095036$yFull text of UNC-digitized copies' \
          '$xocalink_ldss'
        ])
      end

      it 'returns nil for serials that already have a query URL' do
        query = MARC::DataField.new(
          '856', '4', '1',
          ['u', 'https://archive.org/search.php?query=unc_bib_record_id%3Ab2095036']
        )
        bib = described_class.new(
          sierra_bib(bcode1: 's', marc: marc_record(query))
        )
        bib.ia_items = [ia_record]

        expect(bib.m856s_needed).to be_nil
      end

      it 'returns a detail 856 for monographs lacking that URL' do
        bib = described_class.new(sierra_bib(bcode1: 'a'))
        bib.ia_items = [ia_record]

        expect(bib.m856s_needed.map(&:to_mrk)).to eq([
          '=856  41$3v.3$uhttps://archive.org/details/elclavoardiendod550valc' \
          '$yFull text of UNC-digitized copies$xocalink_ldss'
        ])
      end

      it 'does not return a detail 856 when it is already present' do
        detail = MARC::DataField.new(
          '856', '4', '1',
          ['u', 'https://archive.org/details/elclavoardiendod550valc']
        )
        bib = described_class.new(
          sierra_bib(bcode1: 'a', marc: marc_record(detail))
        )
        bib.ia_items = [ia_record]

        expect(bib.m856s_needed).to be_nil
      end
    end
  end
end
