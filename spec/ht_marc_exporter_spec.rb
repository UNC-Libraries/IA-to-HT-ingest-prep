require 'csv'
require 'fileutils'
require 'spec_helper'
require 'tmpdir'

module IaToHtIngestPrep
  RSpec.describe HtMarcExporter do
    let(:today) { Time.now.strftime('%Y%m%d') }

    around do |example|
      Dir.mktmpdir do |directory|
        Dir.chdir(directory) do
          FileUtils.mkdir_p('data')
          example.run
        end
      end
    end

    before do
      record_class = Class.new
      record_class.const_set(:InvalidRecord, Class.new(StandardError))
      stub_const('Sierra::Record', record_class)
      stub_const('Sierra::Derivatives::HathitrustRecord', Class.new)
    end

    def write_inputs(records:, problems: [], excluded_bibs: [], hathi_arks: [])
      CSV.open('search.csv', 'w') do |csv|
        csv << %w[unc_bib_record_id identifier identifier-ark volume]
        records.each { |record| csv << record }
      end
      File.write('nc01.arks.txt', hathi_arks.join("\n"))
      File.write('data/ht_exclude_bib.txt', excluded_bibs.join("\n"))

      unless problems.empty?
        CSV.open('problems.csv', 'w') do |csv|
          csv << ['identifier']
          problems.each { |problem| csv << [problem] }
        end
      end
    end

    def stub_sierra(records, derivatives)
      allow(Sierra::Record).to receive(:get) do |bnum|
        record = records[bnum]
        raise Sierra::Record::InvalidRecord unless record

        record
      end
      allow(Sierra::Derivatives::HathitrustRecord).to receive(:new) do |_bib, ia|
        derivatives.fetch(ia.id)
      end
    end

    def hathi_record(ark:, bnum:, xml: '<record/>', warnings: [])
      hathi = double(ia: double(ark: ark), bnum: bnum, warnings: warnings)
      allow(hathi).to receive(:write_xml) do |outfile:, strict:|
        expect(strict).to be true
        outfile << xml
      end
      hathi
    end

    it 'writes XML and disposition files for a successful record' do
      record = ['b1000001', 'ia-success', 'ark:/13960/success', 'v.1']
      write_inputs(records: [record])
      stub_sierra(
        {'b1000001' => double},
        {'ia-success' => hathi_record(
          ark: 'ark:/13960/success',
          bnum: 'b1000001',
          xml: '<record>success</record>'
        )}
      )

      HtMarcExporter.new.run

      xml_file = "unc_ia-unc_#{today}_ia.xml"
      log_file = "#{today}_ia_log.csv"
      expect(File.read(xml_file)).to include('<record>success</record>')
      expect(File.read(log_file)).to include('wrote xml,')
      expect(File.read('zephir_email.txt')).to include("file name=#{xml_file}")
      expect(File.read('zephir_email.txt')).to include('record count=1')
      expect(File.read('bib_errors.txt')).to include('Excluded 0 ids')
    end

    it 'logs exclusions, missing records, and derivative warnings' do
      records = [
        ['b1000001', 'ia-excluded-bib', 'ark:/13960/excluded-bib', 'v.1'],
        ['b1000002', 'ia-problem', 'ark:/13960/problem', 'v.1'],
        ['b1000003', 'ia-in-ht', 'ark:/13960/in-ht', 'v.1'],
        ['b1000004', 'ia-missing', 'ark:/13960/missing', 'v.1'],
        ['b1000005', 'ia-warning', 'ark:/13960/warning', 'v.1']
      ]
      write_inputs(
        records: records,
        problems: ['ia-problem'],
        excluded_bibs: ['b1000001'],
        hathi_arks: ['ark:/13960/in-ht']
      )
      stub_sierra(
        {
          'b1000001' => double,
          'b1000003' => double,
          'b1000005' => double
        },
        {
          'ia-in-ht' => hathi_record(
            ark: 'ark:/13960/in-ht', bnum: 'b1000003'
          ),
          'ia-warning' => hathi_record(
            ark: 'ark:/13960/warning',
            bnum: 'b1000005',
            warnings: ['invalid MARC']
          )
        }
      )

      HtMarcExporter.new.run

      log = File.read("#{today}_ia_log.csv")
      expect(log).to include('bib on exclude list')
      expect(log).to include('on problems.csv')
      expect(log).to include('record already in HT')
      expect(log).to include('no sierra record')
      expect(log).to include('failed MARC checks')
      expect(File.read('bib_errors.txt')).to include("b1000005\tinvalid MARC")
      expect(File.read('zephir_email.txt')).to include('record count=0')
    end

    it 'reingests listed records that are already in HathiTrust' do
      record = ['b1000001', 'ia-reingest', 'ark:/13960/reingest', 'v.1']
      other_record = ['b1000002', 'ia-not-reingest', 'ark:/13960/other', 'v.1']
      write_inputs(
        records: [record, other_record],
        hathi_arks: ['ark:/13960/reingest']
      )
      File.write('reingest.txt', "ia-reingest\n")
      stub_sierra(
        {'b1000001' => double},
        {'ia-reingest' => hathi_record(
          ark: 'ark:/13960/reingest',
          bnum: 'b1000001',
          xml: '<record>reingest</record>'
        )}
      )

      HtMarcExporter.new(reingest: true).run

      expect(File.read("#{today}_ia_log.csv")).to include('wrote xml,')
      expect(File.read('zephir_email.txt')).to include('record count=1')
      expect(Dir['unc_ia-unc_*_ia.xml'].first).to include('unc_ia-unc_')
    end

    it 'raises when no search records match the reingest list' do
      write_inputs(
        records: [['b1000001', 'ia-other', 'ark:/13960/other', 'v.1']]
      )
      File.write('reingest.txt', "ia-missing\n")

      expect { HtMarcExporter.new(reingest: true).run }.
        to raise_error(
          RuntimeError,
          'No records in search.csv match identifiers in reingest.txt'
        )
    end

    it 'raises when the reingest list is empty' do
      write_inputs(
        records: [['b1000001', 'ia-other', 'ark:/13960/other', 'v.1']]
      )
      File.write('reingest.txt', '')

      expect { HtMarcExporter.new(reingest: true).run }.
        to raise_error(
          RuntimeError,
          'No records in search.csv match identifiers in reingest.txt'
        )
    end
  end
end
