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

    ihash3 = {:unc_bib_record_id=>"b2095036", :identifier=>"elclavoardiendod550valc", :"identifier-ark"=>"", :volume=>"v. 550, no. 2", :publicdate=>"2015-02-02T18:38:50Z", :sponsor=>"University of North Carolina at Chapel Hill", :contributor=>"University Library, University of North Carolina at Chapel Hill", :collection=>"spandr,unclibraries,americana"}
    irec3 = IARecord.new(ihash3)
    it 'sets ark to nil when lacking' do
      expect(irec3.ark).to eq(nil)
    end
    it 'sets warning re missing ark' do
      expect(irec3.warnings).to include('No IA ark')
    end    

    ihash4 = {:unc_bib_record_id=>"", :identifier=>"elclavoardiendod550valc", :"identifier-ark"=>"ark:/13960/t9962ss6m", :volume=>"v. 550, no. 2", :publicdate=>"2015-02-02T18:38:50Z", :sponsor=>"University of North Carolina at Chapel Hill", :contributor=>"University Library, University of North Carolina at Chapel Hill", :collection=>"spandr,unclibraries,americana"}
    irec4 = IARecord.new(ihash4)
    it 'sets bnum to nil when lacking' do
      expect(irec4.bnum).to eq(nil)
    end
    it 'sets warning re missing bnum' do
      expect(irec4.warnings).to include('No bnum in IA')
    end        

    ihash5 = {:unc_bib_record_id=>"b2095036", :identifier=>"elclavoardiendod550valc", :"identifier-ark"=>"ark:/13960/t9962ss6m", :volume=>"", :publicdate=>"2015-02-02T18:38:50Z", :sponsor=>"University of North Carolina at Chapel Hill", :contributor=>"University Library, University of North Carolina at Chapel Hill", :collection=>"spandr,unclibraries,americana"}
    irec5 = IARecord.new(ihash5)
    it 'sets volume to nil when lacking' do
      expect(irec5.volume).to eq(nil)
    end
  end

  describe 'import_search_csv' do
    #todo
  end
  
  describe 'lacks_caption' do
    it 'returns true when volume = 2' do 
      irec = IARecord.new({:unc_bib_record_id=>"b2095036",
                           :identifier=>"elclavoardiendod550valc",
                           :"identifier-ark"=>"ark:/13960/t9962ss6m",
                           :volume=>"2"})
      expect(irec.lacks_caption?).to eq(true)
    end

    it 'returns false when volume is blank' do 
      irec = IARecord.new({:unc_bib_record_id=>"b2095036",
                           :identifier=>"elclavoardiendod550valc",
                           :"identifier-ark"=>"ark:/13960/t9962ss6m",
                           :volume=>""})
      expect(irec.lacks_caption?).to eq(false)
    end

    it 'returns false when volume is bd. 18' do 
      irec = IARecord.new({:unc_bib_record_id=>"b2095036",
                           :identifier=>"elclavoardiendod550valc",
                           :"identifier-ark"=>"ark:/13960/t9962ss6m",
                           :volume=>"bd. 18"})
      expect(irec.lacks_caption?).to eq(false)
    end

    it 'returns false when volume is date' do 
      irec = IARecord.new({:unc_bib_record_id=>"b2095036",
                           :identifier=>"elclavoardiendod550valc",
                           :"identifier-ark"=>"ark:/13960/t9962ss6m",
                           :volume=>"1867"})
      expect(irec.lacks_caption?).to eq(false)
    end

    it 'returns false when volume is ordinal' do 
      irec = IARecord.new({:unc_bib_record_id=>"b2095036",
                           :identifier=>"elclavoardiendod550valc",
                           :"identifier-ark"=>"ark:/13960/t9962ss6m",
                           :volume=>"1st foo"})
      expect(irec.lacks_caption?).to eq(false)
    end

    it 'returns false when volume begins with octothorp' do 
      irec = IARecord.new({:unc_bib_record_id=>"b2095036",
                           :identifier=>"elclavoardiendod550valc",
                           :"identifier-ark"=>"ark:/13960/t9962ss6m",
                           :volume=>"#3"})
      expect(irec.lacks_caption?).to eq(false)
    end
  end

end
