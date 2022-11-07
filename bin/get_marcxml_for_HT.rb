#!/usr/bin/env ruby

require 'csv'
require_relative '../lib/ia_to_ht_ingest_prep.rb'


exporter = IaToHtIngestPrep::HtMarcExporter.new
exporter.run
