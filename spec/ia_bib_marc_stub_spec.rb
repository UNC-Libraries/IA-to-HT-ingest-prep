require 'spec_helper'

module IaToHtIngestPrep
  RSpec.describe IaBibMarcStub do

    describe '#stub' do
      let(:bib) do
        bib = double(IaBib)
        allow(bib).to receive(:marc_stub).and_return(MARC::Record.new)
        allow(bib).to receive(:erec?)
        allow(bib).to receive(:marc).and_return(MARC::Record.new)
        allow(bib).to receive(:oca_items)
        allow(bib).to receive(:serial?).and_return(true)

        bib
      end

      context 'for serial records' do
        it 'returns a serial MARC stub' do
          # blackslashes (signifying empty indicators) need to be escaped
          expected_mrk = <<~MRK
            =LDR            22        4500
            =530  \\\\$aAlso available via the World Wide Web.
            =599  \\\\$aLTIEXP
            =773  0\\$tDigitized by UNC Chapel Hill
            =949  \\1$g1$lerri$h0$rn$t11$u-$jOCA electronic journal
          MRK

          expect(IaBibMarcStub.new(bib).stub([]).to_mrk).to eq(expected_mrk)
        end
      end

      context 'for mono records' do
        it 'returns a mono MARC stub' do
          allow(bib).to receive(:serial?).and_return(false)
          allow(bib).to receive(:mono?).and_return(true)

          # blackslashes (signifying empty indicators) need to be escaped
          expected_mrk = <<~MRK
            =LDR            22        4500
            =530  \\\\$aAlso available via the World Wide Web.
            =599  \\\\$aLTIEXP
            =773  0\\$tDigitized by UNC Chapel Hill
            =949  \\1$g1$lebnb$h0$rn$t11$u-$jOCA electronic book
          MRK

          expect(IaBibMarcStub.new(bib).stub([]).to_mrk).to eq(expected_mrk)
        end
      end

      it 'includes passed 856s in the stub' do
        urls = [MARC::DataField.new('856', '4', '1', ['u', 'https://example.com'])]

        expected_856 = '=856  41$uhttps://example.com'
        expect(IaBibMarcStub.new(bib).stub(urls).to_mrk).to include(expected_856)
      end
    end

    describe '.proper_949' do
      book949 = '=949  \\1$g1$lebnb$h0$rn$t11$u-$jOCA electronic book'
      journal949 = '=949  \\1$g1$lerri$h0$rn$t11$u-$jOCA electronic journal'

      sbmono = IaBibMarcStub.proper_949(:mono)
      it 'returns book 949 for monographs' do
        expect(sbmono.to_mrk).to eq(book949)
      end

      sbserial = IaBibMarcStub.proper_949(:serial)
      it 'returns journal 949 for serials' do
        expect(sbserial.to_mrk).to eq(journal949)
      end
    end

    describe '.proper_530' do
      context 'for print records' do
        sb1 = IaBibMarcStub.proper_530(is_erec: false)

        static_530 = '=530  \\\\$aAlso available via the World Wide Web.'
        it 'returns static 530 field' do
          expect(sb1.to_mrk).to eq(static_530)
        end
      end

      context 'for electronic records' do
        sb1 = IaBibMarcStub.proper_530(is_erec: true)

        it 'returns nil' do
          expect(sb1).to be_nil
        end
      end
    end
  end
end
