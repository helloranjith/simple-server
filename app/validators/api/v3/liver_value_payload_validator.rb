class Api::V3::LiverValuePayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
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
    :hdl_radio,
    :height,
    :weight,
    :platelet_count,
    :hb,
    :apri_score,
    :heb_c,
    :heb_b,
    :heb_b_status,
    :heb_b_date,
    :bmi,
    :uric_acid,
    :creatinine,
    :urine_protine,
    :fatty_liver,
    :fatty_liver_grade,
    :ast,
    :patient_id,
    :facility_id,
    :user_id,
    :created_at,
    :updated_at,
    :deleted_at,
    :recorded_at
  )

  validate :validate_schema
  validate :facility_exists

  def schema
    Api::V3::Models.liver_value
  end

  def facility_exists
    unless Facility.exists?(facility_id)
      Rails.logger.info "Liver value #{id} synced at nonexistent facility #{facility_id}"
      errors.add(:facility_does_not_exist, "Facility does not exist")
    end
  end
end
