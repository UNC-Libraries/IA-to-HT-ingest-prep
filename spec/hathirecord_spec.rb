require_relative '../HathiRecord'

RSpec.describe HathiRecord do

  describe 'my955' do
    irec = IARecord.new(identifier: 'otterbeinhymnalf00chur', "identifier-ark": 'ark:/13960/t05x3dc2n', volume: 'v.2')
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

    irec = IARecord.new(identifier: 'otterbeinhymnalf00chur', "identifier-ark": 'ark:/13960/t05x3dc2n', volume: '')
    rec_2 = HathiRecord.new(srec, irec)

    my955_2 = rec_2.my955
    it '955 does not have subfield v if !volume' do
      expect(my955_2.codes.include?('v')).to be false
    end
  end

  #hathimarc
  #oclcnumber
  #my035s
  describe 'check_marc' do
    
  end
end
