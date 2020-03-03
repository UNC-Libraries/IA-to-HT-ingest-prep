require 'spec_helper'

module IaToHtIngestPrep
  RSpec.describe IaBibMarcStub do

    describe '.proper_949' do
      book949 = '=949  \\1$g1$lebnb$h0$rn$t11$u-$jOCA electronic book'
      journal949 = '=949  \\1$g1$lerri$h0$rn$t11$u-$jOCA electronic journal'

      sbmono = IaBibMarcStub.proper_949(IaBib.new(Sierra::Record.get('b1049731a')))
      it 'returns book 949 for monographs' do
        expect(sbmono.to_mrk).to eq(book949)
      end

      sbserial = IaBibMarcStub.proper_949(IaBib.new(Sierra::Record.get('b1636974a')))
      it 'returns journal 949 for serials' do
        expect(sbserial.to_mrk).to eq(journal949)
      end
    end

    describe '.proper_530' do
      sb1 = IaBibMarcStub.proper_530(IaBib.new(Sierra::Record.get('b1055966a')))
      static_530 = '=530  \\\\$aAlso available via the World Wide Web.'

      it 'returns static 530 field' do
        expect(sb1.to_mrk).to eq(static_530)
      end

      #todo when e-record returns nil
    end
  end
end
