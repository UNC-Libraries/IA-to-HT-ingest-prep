require 'csv'

module IaToHtIngestPrep
  # Handles exporting MARC from Sierra for Sierra bibs / IA identifiers being
  # ingested into Hathitrust. It excludes from export:
  #   - IA items already in HT
  #   - items on a manual exclude list
  #   - items with IA data issues (read from problems.csv)
  #   - items with Sierra bib marc issues
  # and outputs:
  #   - a marxml file to submit to HT
  #   - zephir email text for the email manually sent to zephir
  #   - a list of bib/marc errors
  class HtMarcExporter
    def initialize(reingest_id_list: nil)
      # input = IA search.csv results for prospective HT-ingest
      #   essential fields: bnum, id, ark, vol
      #   standard addl fields: publicdate, sponsor, contributor, collection
      # see readme for query link(s)
      @ia_inventory_file = 'search.csv'

      @ht_unc_arks_file = 'nc01.arks.txt'
      @problems_file = 'problems.csv'
      @manual_bib_excludes_file = 'data/ht_exclude_bib.txt'

      # Optional list of IA identifiers to export. These records will be exported
      # regardless of whether they are already in HT (but may be excluded for
      # other reasons e.g. IA/bib data issues) and only these records will be
      # exported.
      @reingest_id_list = reingest_id_list
    end

    def reingest_ids
      return unless @reingest_id_list

      @reingest_ids ||= File.read(@reingest_id_list).split
    end

    def run
      reingest_ids = File.read('reingest.txt').split if @reingest_id_list

      ifile = IaToHtIngestPrep::IaRecord.import_search_csv(@ia_inventory_file)
      ifile.select! { |r| reingest_ids.include?(r[:identifier]) } if reingest_ids
      headers = ifile[0].keys
      ifile.sort_by! { |r| r[:unc_bib_record_id] }

      # input = arks UNC contributed to HT to date
      arks = File.read(@ht_unc_arks_file).split("\n")

      # input = ia_ids with IA-metadata issues to be excluded from HT-ingest (until fixed)
      problem_ids = []
      if File.file?(@problems_file)
        problem_ids = CSV.read(@problems_file, headers: true)
        problem_ids = problem_ids.to_a[1..-1].map { |r| r[0] }
      end

      # input = bib_record_ids to be excluded from HT-ingest
      #   e.g. some sheet music bibs that were scribed but it was decided should
      #     not be sent to HT
      # if at some point we also want to exclude certain ia_ids (instead of bibs),
      # we can add that
      exclude_bibs = File.read(@manual_bib_excludes_file).split("\n")
      exclude_bibs.select! { |x| x =~ /^b[0-9]+$/ }

      # this logs details of bib/marc errors
      err_log = File.open('bib_errors.txt', 'w')
      # this logs general disposition of everything
      ia_logfile = CSV.open(Time.now.strftime('%Y%m%d') + '_ia_log.csv', 'w')
      ia_logfile << ['reason', headers].flatten

      def ia_log(reason, ia_record, logfile)
        logfile << [reason, ia_record.values].flatten
      end


      problem_id_exclusion = 0

      ofilename = [
        'unc',
        'ia-unc',
        Time.now.strftime('%Y%m%d'),
        'ia'
      ].join('_') + ".xml"

      written_count = 0
      File.open(ofilename,"w:UTF-8") do |xml_out|
        xml_out << MARC::XMLHelper::HEADER
        prev_bnum = nil
        prev_bib = nil
        ifile.each do |ia_record|
          ia = IaToHtIngestPrep::IaRecord.new(ia_record)
          bnum = ia.bib_record_id
          if exclude_bibs.include?(bnum)
            ia_log('bib on exclude list', ia_record, ia_logfile)
            next
          end
          if problem_ids&.include?(ia.id)
            problem_id_exclusion += 1
            ia_log('on problems.csv', ia_record, ia_logfile)
            next
          end

          bib =
            if prev_bnum == bnum
              prev_bib
            else
              begin
                Sierra::Record.get(bnum)
              rescue Sierra::Record::InvalidRecord
                nil
              end
            end
          hathi = Sierra::Derivatives::HathitrustRecord.new(bib, ia) if bib
          puts bnum

          if bib.nil?
            ia_log('no sierra record', ia_record, ia_logfile)
          elsif !hathi.ia.ark
            ia_log('no IA ark_id found', ia_record, ia_logfile)
          elsif arks.include?(hathi.ia.ark) && !reingest_ids
            ia_log('record already in HT', ia_record, ia_logfile)
          else
            hathi.write_xml(outfile: xml_out, strict: true)
            if hathi.warnings.empty?
              written_count += 1
              ia_log('wrote xml', ia_record, ia_logfile)
            else
              ia_log('failed MARC checks', ia_record, ia_logfile)
              hathi.warnings.each do |warning|
                err_log << "#{hathi.bnum}\t#{warning}\n"
              end
            end
          end

          prev_bnum = bnum
          prev_bib = bib
        end
        xml_out << MARC::XMLHelper::FOOTER
      end

      File.open('zephir_email.txt', 'w') do |ofile|
        ofile << "file name=#{ofilename}\n"
        ofile << "file size=#{File.size(ofilename)}\n"
        ofile << "record count=#{written_count}\n"
        ofile << "notification email=eres_cat@unc.edu\n"
      end

      err_log.close
      ia_logfile.close

      errors = File.read('bib_errors.txt').split("\n")
      errors.insert(0, "na\tExcluded #{problem_id_exclusion} ids of the #{problem_ids.length} ids on problems.csv due to...problems. LDSS, if this count is not what you expected, examine.")
      File.write('bib_errors.txt', errors.uniq.join("\n"))
    end
  end
end
