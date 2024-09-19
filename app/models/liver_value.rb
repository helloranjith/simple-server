class LiverValue < ApplicationRecord
  include Mergeable
  include Hashable
  include Observeable
  extend SQLHelpers

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at bp_date registration_facility_name user_id
    lv_ldh iv_tot_bilirubin iv_dir_bilirubin iv_indir_bilirubin iv_tot_cholesterol iv_triglycerides iv_hdl iv_ldl iv_vldl iv_hdl_radio iv_height iv_weight iv_platelet_count iv_hb iv_heb_c iv_heb_b iv_heb_b_status iv_heb_b_date iv_bmi iv_uric_acid iv_creatinine iv_urine_protine iv_fatty_liver iv_fatty_liver_grade iv_ast iv_apri_score]

  # THRESHOLDS = {
  #   critical: {systolic: 180, diastolic: 110},
  #   hypertensive: {systolic: 140, diastolic: 90}
  # }.freeze

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility, optional: true

  has_one :observation, as: :observable
  has_one :encounter, through: :observation

  # has_one :cphc_migration_audit_log, as: :cphc_migratable

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  # scope :hypertensive, -> {
  #   where(arel_table[:systolic].gteq(THRESHOLDS[:hypertensive][:systolic]))
  #     .or(where(arel_table[:diastolic].gteq(THRESHOLDS[:hypertensive][:diastolic])))
  # }

  # scope :under_control, -> {
  #   where(arel_table[:systolic].lt(THRESHOLDS[:hypertensive][:systolic]))
  #     .where(arel_table[:diastolic].lt(THRESHOLDS[:hypertensive][:diastolic]))
  # }

  scope :for_sync, -> { with_discarded }

  scope :for_recent_bp_log, -> do
    recorded_date = "DATE(recorded_at at time zone 'UTC' at time zone '#{CountryConfig.current[:time_zone]}')"
    order(Arel.sql("#{recorded_date} DESC, recorded_at ASC"))
  end

  # def critical?
  #   systolic >= THRESHOLDS[:critical][:systolic] || diastolic >= THRESHOLDS[:critical][:diastolic]
  # end

  # def hypertensive?
  #   systolic >= THRESHOLDS[:hypertensive][:systolic] || diastolic >= THRESHOLDS[:hypertensive][:diastolic]
  # end

  # def under_control?
  #   !hypertensive?
  # end

  def recorded_days_ago
    (Date.current - device_created_at.to_date).to_i
  end

  # def to_s
  #   [systolic, diastolic].join("/")
  # end

  def anonymized_data
    {id: hash_uuid(id),
     patient_id: hash_uuid(patient_id),
     created_at: created_at,
     bp_date: recorded_at,
     registration_facility_name: facility.name,
     user_id: hash_uuid(user_id),
     iv_ldh: ldh,
     iv_tot_bilirubin: tot_bilirubin,
     iv_dir_bilirubin: dir_bilirubin,
     iv_indir_bilirubin: indir_bilirubin,
     iv_tot_cholesterol: tot_cholesterol,
     iv_triglycerides: triglycerides,
     iv_hdl: hdl,
     iv_ldl: ldl,
     iv_vldl: vldl,
     iv_hdl_radio: hdl_radio,
     iv_height: height,
     iv_weight: weight,
     iv_platelet_count: platelet_count,
     iv_hb: hb,
     iv_heb_c: heb_c,
     iv_heb_b: heb_b,
     iv_heb_b_status: heb_b_status,
     iv_heb_b_date: heb_b_date,
     iv_bmi: bmi,
     iv_uric_acid: uric_acid,
     iv_creatinine: creatinine,
     iv_urine_protine: urine_protine,
     iv_fatty_liver: fatty_liver,
     iv_fatty_liver_grade: fatty_liver_grad,
     iv_ast: ast,
     iv_apri_score: apri_score}
  end
end
