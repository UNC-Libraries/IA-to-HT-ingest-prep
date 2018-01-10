require_relative '../HathiRecord'

RSpec.describe HathiRecord do
  describe 'get_ark' do
    it 'retrieves ARK identifier from IA based on IA identifier' do
      expect(HathiRecord.new('b1761015', 'otterbeinhymnalf00chur', 'v.2').get_ark).to(
        eq('ark:/13960/t05x3dc2n')
    )
    end
  end

  describe 'my955' do
    rec = HathiRecord.new('b1761015', 'otterbeinhymnalf00chur', 'v.2')
    rec.ark = 'my_ark'
    my955 = rec.my955
    it "955 has subfields 'b', 'q', 'v' when volume exists" do
      expect(my955.codes).to eq(['b', 'q', 'v'])
    end
    it '955 has ark in subfield b' do
      expect(my955.select { |f| f.code == 'b' }[0].value).to eq('my_ark')
    end
    it '955 has ia_id in subfield q' do
      expect(my955.select { |f| f.code == 'q' }[0].value).to eq('otterbeinhymnalf00chur')
    end
    it '955 has volume in subfield v if volume' do
      expect(my955.select { |f| f.code == 'v' }[0].value).to eq('v.2')
    end
    rec_2 = HathiRecord.new('b1761015', 'otterbeinhymnalf00chur', '')
    my955_2 = rec_2.my955
    it '955 does not have subfield v if !volume' do
      expect(my955_2.codes.include?('v')).to be false
    end
  end

  #hathimarc
  #oclcnumber
  #my035s
  #check_marc
end
