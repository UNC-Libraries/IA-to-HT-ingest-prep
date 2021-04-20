require 'spec_helper'

module IaToHtIngestPrep
  RSpec.describe IASierra856 do
    sbmono = IaBib.new(Sierra::Record.get('b1049731a'))
    sbserial = IaBib.new(Sierra::Record.get('b1636974a'))
    irec = IaRecord.new({:unc_bib_record_id=>"b2095036",
      :identifier=>"elclavoardiendod550valc",
      :"identifier-ark"=>"ark:/13960/t9962ss6m",
      :volume=>"v.3"})

    describe 'proper_sfu' do
      serial856 = IASierra856.new(sbserial, irec)
      it 'returns query url for serial bib' do
        expect(serial856.proper_sfu.value).to match(/archive\.org\/search\.php/)
      end
      it 'uses bib_record_id for serial bib' do
        expect(serial856.proper_sfu.value).to match(/unc_bib_record_id%3Ab2095036$/)
      end

      irec = IaRecord.new({:identifier=>"elclavoardiendod550valc",
        :"identifier-ark"=>"ark:/13960/t9962ss6m",
        :volume=>"v.3"})
      serial856_2 = IASierra856.new(sbserial, irec)
      it 'is nil if serial bib and IA data has no bib_record_id' do
        expect(serial856_2.proper_sfu).to be_nil
      end


      mono856 = IASierra856.new(sbmono, irec)
      it 'returns detail url for mono bib' do
        expect(mono856.proper_sfu.value).to match(/archive\.org\/details/)
      end
      it 'uses ia_id for mono' do
        expect(mono856.proper_sfu.value).to match(/\/details\/elclavoardiendod550valc$/)
      end

      irec = IaRecord.new({:unc_bib_record_id=>"b2095036",
        :"identifier-ark"=>"ark:/13960/t9962ss6m",
        :volume=>"v.3"})
      mono856_2 = IASierra856.new(sbmono, irec)
      it 'is nil if mono bib and IA data has no ia_id' do
        expect(mono856_2.proper_sfu).to be_nil
      end
    end

    describe 'proper_sfy' do
      static_sfy = 'Full text available via the UNC-Chapel Hill Libraries'
      mono856 = IASierra856.new(sbmono, irec)

      it 'returns standard 856$y' do
        expect(mono856.proper_sfy.value).to eq(static_sfy)
      end
    end

    describe 'proper_sf3' do

      sb1 = IaBib.new(Sierra::Record.get('b1050138a'))
      mono856 = IASierra856.new(sb1, irec)
      mono_sf3 = mono856.proper_sf3.value
      it 'begins "Internet Archive" if bib includes non-IA links to content' do
        expect(mono_sf3).to match(/^Internet Archive/)
      end
      it 'contains ia.volume data for monographs' do
        expect(mono_sf3).to match(/v.3$/)
      end
      it 'properly joins IA prefix and ia.volume data' do
        expect(mono_sf3).to eq('Internet Archive, v.3')
      end

      sb2 = IaBib.new(Sierra::Record.get('b1317054a'))
      serial856_1 = IASierra856.new(sb2, irec)
      it 'does not contain ia.volume data for serials' do
        expect(serial856_1.proper_sf3&.value).to be_nil.or eq('Internet Archive')
      end

      sb3 = IaBib.new(Sierra::Record.get('b2043737a'))
      serial856_2 = IASierra856.new(sb3, irec)
      it 'does not begin "Internet Archive" if bib only includes IA links' do
        expect(serial856_2.proper_sf3).to be_nil
      end

    end


    describe 'proper_ind2' do
    end

    describe 'proper_856' do
    end

  end
end
