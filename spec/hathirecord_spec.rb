require_relative '../HathiRecord'

RSpec.describe HathiRecord do

  describe 'my955' do
    irec = IARecord.new({:identifier => 'otterbeinhymnalf00chur', :'identifier-ark' => 'ark:/13960/t05x3dc2n', :volume =>'v.2'})
    srec = SierraBib.new('b1761015')
    rec = HathiRecord.new(srec, irec)
    my955 = rec.my955
    it "955 has subfields 'b', 'q', 'v' when volume exists" do
      expect(my955.codes).to eq(['b', 'q', 'v'])
    end
    it '955 has ark in subfield b' do
      expect(my955.select { |f| f.code == 'b' }[0].value).to eq('ark:/13960/t05x3dc2n')
    end
    it '955 has ia_id in subfield q' do
      expect(my955.select { |f| f.code == 'q' }[0].value).to eq('otterbeinhymnalf00chur')
    end
    it '955 has volume in subfield v if volume' do
      expect(my955.select { |f| f.code == 'v' }[0].value).to eq('v.2')
    end

    irec2 = IARecord.new({:identifier => 'otterbeinhymnalf00chur', :'identifier-ark' => 'ark:/13960/t05x3dc2n'})
    rec_2 = HathiRecord.new(srec, irec2)

    my955_2 = rec_2.my955
    it '955 does not have subfield v if !volume' do
      expect(my955_2.codes.include?('v')).to be false
    end
  end

  describe 'initialize' do
    it 'writes warning re: lack of ark to HathiRecord' do
      srec = SierraBib.new('b1761015')
      irec = IARecord.new({:identifier => 'otterbeinhymnalf00chur', :volume =>'v.2'})
      rec = HathiRecord.new(srec, irec)
      expect(rec.warnings).to include('No Ark could be found for this record. Report record to LDSS.')
    end

    it 'writes warning re: no Sierra record found' do
      srec = SierraBib.new('bxr291761015')
      irec = IARecord.new({:identifier => 'otterbeinhymnalf00chur', :'identifier-ark' => 'ark:/13960/t05x3dc2n'})
      rec = HathiRecord.new(srec, irec)
      expect(rec.warnings).to include('No record was found in Sierra for this bnum')
    end

    it 'does not write "no Sierra record found" warning when bib deleted' do
      srec = SierraBib.new('b6780003')
      irec = IARecord.new({:identifier => 'otterbeinhymnalf00chur', :'identifier-ark' => 'ark:/13960/t05x3dc2n'})
      rec = HathiRecord.new(srec, irec)
      expect(rec.warnings).to_not include('No record was found in Sierra for this bnum')
    end

    it 'writes warning re: deleted Sierra records when bib deleted' do
      srec = SierraBib.new('b6780003')
      irec = IARecord.new({:identifier => 'otterbeinhymnalf00chur', :'identifier-ark' => 'ark:/13960/t05x3dc2n'})
      rec = HathiRecord.new(srec, irec)
      expect(rec.warnings).to include('Sierra bib for this bnum was deleted')
    end

  end

  #hathimarc
  #oclcnumber
  #my035s
  describe 'check_marc' do

  end

  describe '#xml' do
    let(:srec) { SierraBib.new('b1841152a') }
    let(:irec) { IARecord.new({:identifier => 'otterbeinhymnalf00chur',
                               :'identifier-ark' => 'ark:/13960/t05x3dc2n',
                               :volume => 'v.2'}) }
    let(:rec) { HathiRecord.new(srec, irec) }
    let(:expected) { File.open('spec/data/b1841152a.ht.xml').read }

    # nothing special about b1841152a
    it 'produces expected xml for b1841152a' do
      expect(rec.xml).to eq(expected)
    end
  end
end
