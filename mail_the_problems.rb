require 'yaml'
require 'mail'


mailbody = <<-BODY
Hi {branchname},

Attached is a list of IA items with metadata problems for collections you manage.

For more info, please see:
https://adminliveunc.sharepoint.com/sites/lib/kb/SiteAssets/LibWiki/SCRIBE%20Book%20Digitization/IA_metadata_corrections.docx

Please:
  1) add corrections to the empty "volume" field of the attached list,
  2) send corrected items in an attached .csv or .xlsx file
      to: eres_cat@unc.edu
      subject line: "IA/Scribe metadata corrections to load"

Please remember that the corrections you send will be loaded directly into IA,
overwriting IA's current metadata, without any further checks. So please take
appropriate measures to ensure your corrections have been entered correctly.

Thanks,
LDSS/E-Resources Cataloging
eres_cat@unc.edu
BODY


emails = YAML.load_file('branch_emails.yaml')

# Add in existing branch problem files
pfiles = Dir["branch_problems/*_ia_problems_*.csv"]
pfiles.each do |filename|
  raise "Empty file?: #{filename}" unless File.size?(filename)
  branch = filename.match(/ia_problems_(.*).csv/)[1]
  raise "Unrecognized file should not be present" if branch == 'unrecognized'
  emails[branch]['filename'] = filename
end
emails.delete_if { |k, v| v['filename'] == nil }

# Abort if we lack email addresses for problem files
no_emails = emails.select { |k,v| v['filename'] != '' && v['email'] == nil }
unless no_emails.empty?
  puts error = <<~EOL
    need emails for:
    #{no_emails.keys.join("\n")}
    Aborting."
  EOL
  raise 'There are problem files without email addresses. Aborting.'
end


# Confirm sending emails
puts <<-EOL
\n\nYou're about to send #{emails.length} emails for these problem files:\n
#{emails.values.map { |r| r['filename'] }.join("\n")}
\nAre those the correct dates/files?
If you want to proceed, enter "send emails". Anything else will abort.
What do you want to do?
EOL
confirmation = gets.chomp
raise 'No confirmation. Aborting' unless confirmation == 'send emails'

# Send emails
Mail.defaults do
  delivery_method :smtp, address: "relay.unc.edu", port: 25
end

emails.each do |k, v|
  email_to = v['email']
  puts "emailing #{k} problems to #{email_to}"
  attachment = v['filename']
  Mail.deliver do
    from     'eres_cat@unc.edu'
    to       email_to
    cc       'eres_cat@unc.edu'
    subject  'IA/Scribe metadata problems for correction'
    body     mailbody.gsub('{branchname}', k)
    add_file attachment
  end
end