class IARecord
  attr_reader :id, :volume, :ark, :misc

  def initialize(ia_identifier, ark_id, volume, misc = nil)
    @id = ia_identifier.to_s.strip
    @volume = volume.to_s.strip
    @ark = ark_id.to_s.strip
    @misc = misc
  end
end