require "bundler/setup"

# These specs use local fixtures and test doubles, not a Sierra connection.
# Defer s-p-u's automatic connection so the suite does not require credentials.
ENV['SIERRA_DELAY_CONNECT'] = '1'

require "ia_to_ht_ingest_prep"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
