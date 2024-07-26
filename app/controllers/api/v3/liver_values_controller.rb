class Api::V3::LiverValuesController < Api::V3::SyncController
  include Api::V3::SyncEncounterObservation
  include Api::V3::RetroactiveDataEntry

  def sync_from_user
    __sync_from_user__(liver_values_params)
  end

  def sync_to_user
    __sync_to_user__("liver_values")
  end

  private

  def merge_if_valid(bp_params)
    validator = Api::V3::LiverValuePayloadValidator.new(bp_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      set_patient_recorded_at(bp_params)
      transformed_params = Api::V3::LiverValueTransformer.from_request(bp_params)
      {record: merge_encounter_observation(:liver_values, transformed_params)}
    end
  end

  def transform_to_response(liver_value)
    Api::V3::Transformer.to_response(liver_value)
  end

  def liver_values_params
    params.require(:liver_values).map do |liver_value_params|
      liver_value_params.permit(
        :id,
        :ldh,
        :tot_bilirubin,
        :dir_bilirubin,
        :indir_bilirubin,
        :tot_cholesterol,
        :triglycerides,
        :hdl,
        :ldl,
        :vldl,
        :height,
        :weight,
        :platelet_count,
        :hb,
        :platelet_count,
        :platelet_count,
        :platelet_count,
        :patient_id,
        :facility_id,
        :user_id,
        :created_at,
        :updated_at,
        :recorded_at,
        :deleted_at
      )
    end
  end
end
