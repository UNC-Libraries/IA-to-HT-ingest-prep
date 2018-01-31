require_relative '../IARecord'

RSpec.describe IARecord do

  describe 'initialize' do
    ihash1 = {:unc_bib_record_id=>"b2095036", :identifier=>"elclavoardiendod550valc", :"identifier-ark"=>"ark:/13960/t9962ss6m", :volume=>"v. 550, no. 2", :publicdate=>"2015-02-02T18:38:50Z", :sponsor=>"University of North Carolina at Chapel Hill", :contributor=>"University Library, University of North Carolina at Chapel Hill", :collection=>"spandr,unclibraries,americana"}
    irec1= IARecord.new(ihash1)

    it 'sets id' do
      expect(irec1.id).to eq('elclavoardiendod550valc')
    end

    it 'sets volume' do
      expect(irec1.volume).to eq('v. 550, no. 2')
    end

    it 'sets ark' do
      expect(irec1.ark).to eq('ark:/13960/t9962ss6m')
    end

    it 'sets bnum' do
      expect(irec1.bnum).to eq('b2095036')
    end

    ihash2 = {:unc_bib_record_id=>"b2095036", :identifier=>"", :"identifier-ark"=>"ark:/13960/t9962ss6m", :volume=>"v. 550, no. 2", :publicdate=>"2015-02-02T18:38:50Z", :sponsor=>"University of North Carolina at Chapel Hill", :contributor=>"University Library, University of North Carolina at Chapel Hill", :collection=>"spandr,unclibraries,americana"}
    irec2 = IARecord.new(ihash2)
    it 'sets id to nil when lacking' do
      expect(irec2.id).to eq(nil)
    end
    it 'sets warning re missing id' do
      expect(irec2.warnings).to include('No IA id')
    end

    ihash3 = {:unc_bib_record_id=>"b2095036", :identifier=>"", :"identifier-ark"=>"ark:/13960/t9962ss6m", :volume=>"v. 550, no. 2", :publicdate=>"2015-02-02T18:38:50Z", :sponsor=>"University of North Carolina at Chapel Hill", :contributor=>"University Library, University of North Carolina at Chapel Hill", :collection=>"spandr,unclibraries,americana"}
    irec3 = IARecord.new(ihash3)
    it 'sets id to nil when lacking' do
      expect(irec3.id).to eq(nil)
    end
    it 'sets warning re missing id' do
      expect(irec3.warnings).to include('No IA id')
    end    
  end

  describe 'lacks_caption' do
  end

end
