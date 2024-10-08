class ImportUser
  def self.find_or_create(org_id:)
    find(org_id) || create(org_id)
  end

  def self.find(org_id)
    PhoneNumberAuthentication.joins(:user)
      .find_by(phone_number: bot_phone_number(org_id), user: {organization_id: org_id})&.user
  end

  def self.create(org_id)
    facility = Organization.find_by(id: org_id).facilities.first
    unless facility.present?
      raise ArgumentError, "given organization: #{org_id} does not exist or has no facilities"
    end

    user = User.new(
      full_name: "import-user",
      organization_id: facility.organization.id,
      device_created_at: Time.current,
      device_updated_at: Time.current
    )

    phone_number_authentication = PhoneNumberAuthentication.new(
      phone_number: bot_phone_number(org_id),
      password: generate_pin,
      registration_facility_id: facility.id
    ).tap do |pna|
      pna.set_otp
      pna.invalidate_otp
      pna.set_access_token
    end

    user.phone_number_authentications = [phone_number_authentication]
    user.sync_approval_denied("bot user for import")
    user.save!

    user
  end

  def self.generate_pin
    "#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}"
  end

  def self.bot_phone_number(org_id)
    # Losslessly compresses an organisation UUID value into a url-safe base64 representation.
    # This is a bit more compact than stuffing a UUID string as a phone number directly. Other
    # forms of hashing may lead to information loss, doing it this way keeps the collision
    # probability the same as the organization UUID itself.
    [[org_id.remove("-")].pack("H*")].pack("m0").tr("+/", "-_")[..21]
  end
end
