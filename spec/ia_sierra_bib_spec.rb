require 'spec_helper'

module IaToHtIngestPrep
  RSpec.describe IaBib do

    describe 'oca_items' do

      oca_bib = IaBib.new(Sierra::Record.get('b1055966a'))
      it 'includes oca items' do
        expect(oca_bib.oca_items.any? { |i| i.inum == 'i10105652a'}).to be true
      end

      it 'excludes non-oca items' do
        expect(oca_bib.oca_items.count).to eq(1)
      end

      no_oca_bib = IaBib.new(Sierra::Record.get('b1000001a'))
      it 'nil when no oca items' do
        expect(no_oca_bib.oca_items).to be nil
      end
    end

    describe '#ia_rec_type' do
      sb1 = IaBib.new(Sierra::Record.get('b1636974a'))
      it 'is serial if bcode1 is "s"' do
        expect(sb1.ia_rec_type).to eq('serial')
      end

      sb2 = IaBib.new(Sierra::Record.get('b9429410a'))
      it 'is serial if bcode1 is "b"' do
        expect(sb2.ia_rec_type).to eq('serial')
      end

      sb3 = IaBib.new(Sierra::Record.get('b3225942a'))
      it 'is mono if bcode1 is "a"' do
        expect(sb3.ia_rec_type).to eq('mono')
      end

      sb4 = IaBib.new(Sierra::Record.get('b3811763a'))
      it 'is mono if bcode1 is "c"' do
        expect(sb3.ia_rec_type).to eq('mono')
      end

      sb5 = IaBib.new(Sierra::Record.get('b1039641a'))
      it 'is mono if bcode1 is "m"' do
        expect(sb3.ia_rec_type).to eq('mono')
      end
    end

    describe 'has_query_url' do

      sb1 = IaBib.new(Sierra::Record.get('b1636974a'))
      it 'is true if query url is present in an 856u' do
        expect(sb1.has_query_url?).to be true
      end

      sb2 = IaBib.new(Sierra::Record.get('b1024783a'))
      it 'is false if no query url present' do
        expect(sb2.has_query_url?).to be false
      end
    end

    describe 'ia_ids_in_856u' do

      sb1 = IaBib.new(Sierra::Record.get('b1156369a'))
      result = sb1.ia_ids_in_856u
      ids = ['londonlabourlond01mayh', 'londonlabourlond02mayh_0',
            'londonlabourlond03mayh_0', 'londonlabourlond04mayh_0']

      it 'returns array' do
        expect(result).to be_an(Array)
      end

      it "lists ia identifiers in bib's 856u's" do
        expect(result).to eq(ids)
      end

      sb2 = IaBib.new(Sierra::Record.get('b1636974a'))
      it 'returns nil if no ia ids' do
        expect(sb2.ia_ids_in_856u).to be_nil
      end
    end

    describe 'm856s_needed' do
      irec = IaRecord.new({:unc_bib_record_id=>"b2095036",
        :identifier=>"elclavoardiendod550valc",
        :"identifier-ark"=>"ark:/13960/t9962ss6m",
        :volume=>"v.3"})

      sbserial = IaBib.new(Sierra::Record.get('b1484972a'))
      sbserial.ia_items = [irec]
      sbserial_neededmrk = sbserial.m856s_needed.map(&:to_mrk)
      my_query = ["=856  41$uhttps://archive.org/search.php?sort=publicdate&query=scanningcenter%3Achapelhill+AND+mediatype%3Atexts+AND+unc_bib_record_id%3Ab2095036$yFull text of UNC-digitized copies$xocalink_ldss"]
      it 'returns query 856 for serials lacking query 856' do
        expect(sbserial_neededmrk).to eq(my_query)
      end

      sbserial2 = IaBib.new(Sierra::Record.get('b1636974a'))
      sbserial2.ia_items = [irec]
      it 'returns nil for serials that have query 856' do
        expect(sbserial2.m856s_needed).to be_nil
      end

      sbmono = IaBib.new(Sierra::Record.get('b1156369a'))
      sbmono.ia_items = [irec]
      sbmono_neededmrk = sbmono.m856s_needed.map(&:to_mrk)
      my_detail = ["=856  41$3v.3$uhttps://archive.org/details/elclavoardiendod550valc$yFull text of UNC-digitized copies$xocalink_ldss"]
      it 'returns detail 856 for mono lacking that 856' do
        expect(sbmono_neededmrk).to eq(my_detail)
      end

      sbmono2 = IaBib.new(Sierra::Record.get('b2095036a'))
      sbmono2.ia_items = [irec]
      sbmono2_neededmrk = sbmono2.m856s_needed&.map(&:to_mrk)
      it 'does not return detail 856 when already present on mono' do
        expect(sbmono2_neededmrk).to be_nil
      end
    end

    describe 'relevant_nonIA_856s' do
      #nil if only IA 856s
    end
  end
end

=begin
      describe 'has_0A_530
      describe serial
      describe mono

    IASierra956 proper 856
=end
