class Api::V3::LiverValuesController < Api::V3::SyncController
  include Api::V3::SyncEncounterObservation
  include Api::V3::RetroactiveDataEntry

  def sync_from_user
    __sync_from_user__(liver_values_params)
  end

  def sync_to_user
    __sync_to_user__("liver_values")
  end

  def insert_liver

    res1 = Array.new
    liverDatas = params["liver_values"]
    liverDatas.each do |liver|
      begin
        key = ""
        value = ""

        if(liver["heb_c"] != nil && liver["heb_c"] != "")
          key = "#{key},heb_c"
          value = "#{value},'#{liver["heb_c"]}'"
        end
        
        if(liver["heb_b"] != nil && liver["heb_b"] != "")
          key = "#{key},heb_b"
          value = "#{value},'#{liver["heb_b"]}'"
        end
      
        if(liver["heb_b_status"] != nil && liver["heb_b_status"] != "")
          key = "#{key},heb_b_status"
          value = "#{value},'#{liver["heb_b_status"]}'"
        end
      
        if(liver["heb_b_date"] != nil && liver["heb_b_date"] != "")
          key = "#{key},heb_b_date"
          value = "#{value},'#{liver["heb_b_date"]}'"
        end
      
        if(liver["bmi"] != nil && liver["bmi"] != "")
          key = "#{key},bmi"
          value = "#{value},'#{liver["bmi"]}'"
        end
      
        if(liver["uric_acid"] != nil && liver["uric_acid"] != "")
          key = "#{key},uric_acid"
          value = "#{value},'#{liver["uric_acid"]}'"
        end
      
        if(liver["creatinine"] != nil && liver["creatinine"] != "")
          key = "#{key},creatinine"
          value = "#{value},'#{liver["creatinine"]}'"
        end
      
        if(liver["urine_protine"] != nil && liver["urine_protine"] != "")
          key = "#{key},urine_protine"
          value = "#{value},'#{liver["urine_protine"]}'"
        end
      
      
        if(liver["fatty_liver"] != nil && liver["fatty_liver"] != "")
          key = "#{key},fatty_liver"
          value = "#{value},'#{liver["fatty_liver"]}'"
        end
      
      
        if(liver["fatty_liver_grade"] != nil && liver["fatty_liver_grade"] != "")
          key = "#{key},fatty_liver_grade"
          value = "#{value},'#{liver["fatty_liver_grade"]}'"
        end
      
        q = "INSERT INTO liver_values (id,patient_id,created_at,updated_at,facility_id,user_id,recorded_at,ldh,tot_bilirubin,dir_bilirubin,indir_bilirubin,tot_cholesterol,triglycerides,hdl,ldl,vldl,hdl_radio,height,weight,platelet_count,hb,apri_score,ast#{key}) VALUES ('#{liver["id"]}','#{liver["patient_id"]}','#{liver["created_at"]}','#{liver["updated_at"]}','#{liver["facility_id"]}','#{liver["user_id"]}','#{liver["recorded_at"]}','#{liver["ldh"]}','#{liver["tot_bilirubin"]}','#{liver["dir_bilirubin"]}','#{liver["indir_bilirubin"]}','#{liver["tot_cholesterol"]}','#{liver["triglycerides"]}','#{liver["hdl"]}','#{liver["ldl"]}','#{liver["vldl"]}','#{liver["hdl_radio"]}','#{liver["height"]}','#{liver["weight"]}','#{liver["platelet_count"]}','#{liver["hb"]}','#{liver["apri_score"]}','#{liver["ast"]}'#{value})"
        ins = ActiveRecord::Base.connection().execute(q)
        # ins = LiverValue.new(:id => liver["id"],:patient_id => liver["patient_id"], :facility_id => liver["facility_id"], :user_id => liver["user_id"], :height => liver["height"], :weight => liver["weight"], :ast => liver["ast"], :platelet_count => liver["platelet_count"], :hb => liver["hb"], :ldh => liver["ldh"], :tot_bilirubin => liver["tot_bilirubin"], :dir_bilirubin => liver["dir_bilirubin"], :indir_bilirubin => liver["indir_bilirubin"], :tot_cholesterol => liver["tot_cholesterol"], :triglycerides => liver["triglycerides"], :hdl => liver["hdl"], :ldl => liver["ldl"], :vldl => liver["vldl"], :hdl_radio => liver["hdl_radio"], :apri_score => liver["apri_score"], :created_at => liver["created_at"], :updated_at => liver["updated_at"], :recorded_at => liver["recorded_at"])
        # ins.save

        # re = Hash.new
        # re["id"]= liver["id"]
        # re["q"]= q
        # re["schema"]= ["string"]
        # re["field_with_error"]= ["string"]
        # res1 << re 

      rescue Exception => e
        err = Hash.new
        err["id"] = liver["id"]
        schema_err = Array.new
        schema_err << e
        err["schema"] = schema_err
        res1 << err
      end
    end


    render :json => { :errors => res1}
    return


  end

  private

  def merge_if_valid(bp_params)
    validator = Api::V3::LiverValuePayloadValidator.new(bp_params)
    logger.debug "Liver values had errors: '#{validator.errors_hash}" if validator.invalid?
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

  # def liver_values_params
  #   params.require(:liver_values).map do |liver_value_params|
  #     liver_value_params.permit(
  #       :id,
  #       :platelet_count,
  #       :patient_id,
  #       :facility_id,
  #       :user_id,
  #       :created_at,
  #       :updated_at,
  #       :recorded_at,
  #       :deleted_at
  #     )
  #   end
  # end

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
        :hdl_radio,
        :height,
        :weight,
        :platelet_count,
        :hb,
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
        :apri_score,
        :ast,
        :patient_id,
        :facility_id,
        :user_id,
        :created_at,
        :updated_at,
        :recorded_at
      )
    end
  end

end
