module IaToHtIngestPrep
  # IA logic added to Sierra item records
  module IaSierraItem
    def oca?
      stats_fields.any? { |x| x.match(/OCA electronic (?:book|journal)/i) }
    end
  end
end

module Sierra
  module Data
    class Item
      include IaToHtIngestPrep::IaSierraItem
    end
  end
end
