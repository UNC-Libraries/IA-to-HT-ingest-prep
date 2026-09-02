require 'spec_helper'

module IaToHtIngestPrep
  RSpec.describe IASierra856 do
    def marc_record(*fields)
      MARC::Record.new.tap do |record|
        fields.each { |field| record.append(field) }
      end
    end

    def bib(serial:, mono:, marc: MARC::Record.new, erec: false)
      double(serial?: serial, mono?: mono, marc: marc, erec?: erec)
    end

    let(:ia_record) do
      IaRecord.new(
        :unc_bib_record_id => 'b2095036',
        :identifier => 'elclavoardiendod550valc',
        :'identifier-ark' => 'ark:/13960/t9962ss6m',
        :volume => 'v.3'
      )
    end

    let(:serial_bib) { bib(serial: true, mono: false) }
    let(:mono_bib) { bib(serial: false, mono: true) }

    describe 'proper_sfu' do
      it 'returns query url for serial bib' do
        result = IASierra856.new(serial_bib, ia_record)
        expect(result.proper_sfu.value).to match(/archive\.org\/search\.php/)
      end

      it 'uses bib_record_id for serial bib' do
        result = IASierra856.new(serial_bib, ia_record)
        expect(result.proper_sfu.value).to match(/unc_bib_record_id%3Ab2095036$/)
      end

      it 'is nil if serial bib and IA data has no bib_record_id' do
        ia_without_bib = IaRecord.new(
          :identifier => 'elclavoardiendod550valc',
          :'identifier-ark' => 'ark:/13960/t9962ss6m',
          :volume => 'v.3'
        )
        result = IASierra856.new(serial_bib, ia_without_bib)
        expect(result.proper_sfu).to be_nil
      end

      it 'returns detail url for mono bib' do
        result = IASierra856.new(mono_bib, ia_record)
        expect(result.proper_sfu.value).to match(/archive\.org\/details/)
      end

      it 'uses ia_id for mono' do
        result = IASierra856.new(mono_bib, ia_record)
        expect(result.proper_sfu.value).to match(/\/details\/elclavoardiendod550valc$/)
      end

      it 'is nil if mono bib and IA data has no ia_id' do
        ia_without_id = IaRecord.new(
          :unc_bib_record_id => 'b2095036',
          :'identifier-ark' => 'ark:/13960/t9962ss6m',
          :volume => 'v.3'
        )
        result = IASierra856.new(mono_bib, ia_without_id)
        expect(result.proper_sfu).to be_nil
      end
    end

    describe 'proper_sfy' do
      it 'returns standard 856$y' do
        result = IASierra856.new(mono_bib, ia_record)
        expect(result.proper_sfy.value).to eq('Full text of UNC-digitized copies')
      end
    end

    describe 'proper_sf3' do
      it 'begins "Internet Archive" if bib includes non-IA links to content' do
        non_ia = MARC::DataField.new('856', '4', '1', ['u', 'https://example.com'])
        result = IASierra856.new(
          bib(serial: false, mono: true, marc: marc_record(non_ia)), ia_record
        )
        expect(result.proper_sf3.value).to start_with('Internet Archive')
      end

      it 'contains ia.volume data for monographs' do
        result = IASierra856.new(mono_bib, ia_record)
        expect(result.proper_sf3.value).to eq('v.3')
      end

      it 'properly joins IA prefix and ia.volume data' do
        non_ia = MARC::DataField.new('856', '4', '1', ['u', 'https://example.com'])
        result = IASierra856.new(
          bib(serial: false, mono: true, marc: marc_record(non_ia)), ia_record
        )
        expect(result.proper_sf3.value).to eq('Internet Archive, v.3')
      end

      it 'does not contain ia.volume data for serials' do
        result = IASierra856.new(serial_bib, ia_record)
        expect(result.proper_sf3).to be_nil
      end

      it 'does not begin "Internet Archive" if bib only includes IA links' do
        ia_link = MARC::DataField.new('856', '4', '1', ['u', 'https://archive.org/details/foo'])
        result = IASierra856.new(
          bib(serial: false, mono: true, marc: marc_record(ia_link)), ia_record
        )
        expect(result.proper_sf3&.value).not_to start_with('Internet Archive')
      end
    end

    describe 'proper_ind2' do
      it 'uses indicator 1 for print records' do
        result = IASierra856.new(mono_bib, ia_record)
        expect(result.proper_ind2).to eq('1')
      end

      it 'uses indicator 0 for e-records' do
        erec_bib = bib(serial: false, mono: true, erec: true)
        result = IASierra856.new(erec_bib, ia_record)
        expect(result.proper_ind2).to eq('0')
      end
    end

    describe 'proper_856' do
      it 'builds the complete 856 field' do
        result = IASierra856.new(mono_bib, ia_record)
        expect(result.proper_856.to_mrk).to eq(
          '=856  41$3v.3$uhttps://archive.org/details/elclavoardiendod550valc' \
          '$yFull text of UNC-digitized copies$xocalink_ldss'
        )
      end
    end
  end
end
