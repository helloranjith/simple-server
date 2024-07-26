class Api::V3::LiverValueTransformer < Api::V3::Transformer
  class << self
    def recorded_at(liver_value_payload)
      liver_value_payload["recorded_at"] || liver_value_payload["device_created_at"]
    end

    def from_request(liver_value_payload)
      attributes = super(liver_value_payload)
      attributes.merge("recorded_at" => recorded_at(attributes))
    end
  end
end
