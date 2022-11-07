#!/usr/bin/env ruby

require 'csv'
require_relative '../lib/ia_to_ht_ingest_prep.rb'

if ARGV.include?('--reingest')
  exporter = IaToHtIngestPrep::HtMarcExporter.new(reingest_id_list: 'reingest.txt')
else
  exporter = IaToHtIngestPrep::HtMarcExporter.new
end
exporter.run
