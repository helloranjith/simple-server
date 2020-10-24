class RegionBackfill
  def self.call(*args)
    new(*args).call
  end

  class UnsupportedCountry < RuntimeError; end

  attr_reader :logger
  attr_reader :invalid_counts
  attr_reader :success_counts

  def initialize(dry_run: true)
    @dry_run = dry_run
    @write = !@dry_run
    @logger = Rails.logger.child(class: self.class.name, dry_run: dry_run)
    @success_counts = {}
    @invalid_counts = {}
  end

  def dry_run?
    @dry_run
  end

  def write?
    @write
  end

  def call
    create_region_types
    create_regions
    logger.info msg: "complete", success_counts: success_counts, invalid_counts: invalid_counts
  end

  NullRegion = Struct.new(:name, keyword_init: true) {
    def path
      nil
    end
  }

  def create_regions
    current_country_name = CountryConfig.current[:name]
    if current_country_name != "India" && !dry_run?
      raise UnsupportedCountry, "#{self.class.name} not yet ready to run in write mode in #{current_country_name}"
    end
    root_type = find_region_type("Root")
    org_type = find_region_type("Organization")
    state_type = find_region_type("State")
    facility_group_type = find_region_type("District")
    block_type = find_region_type("Block")
    facility_type = find_region_type("Facility")

    root_parent = NullRegion.new(name: "__root__")
    instance = create_region_from name: current_country_name, region_type: root_type, parent: root_parent

    Organization.all.each do |org|
      org_region = create_region_from(source: org, region_type: org_type, parent: instance)

      state_names = org.facilities.distinct.pluck(:state)
      states = state_names.each_with_object({}) { |name, hsh|
        hsh[name] = create_region_from(name: name, region_type: state_type, parent: org_region)
      }

      org.facilities.find_each do |facility|
        state = states.fetch(facility.state) { |name| "Could not find state #{name}" }
        facility_group = facility.facility_group
        district = create_region_from(source: facility_group, region_type: facility_group_type, parent: state)
        if facility.block.blank?
          count_invalid(block_type)
          logger.info msg: "Skipping creation of Facility #{facility.name} because the block field (ie zone) is blank",
                      error: "block is blank",
                      block_name: block_name,
                      facilities: facilities.map(&:name)
          next
        end
        block_region = create_region_from(name: facility.block, region_type: block_type, parent: district)
        create_region_from(source: facility, region_type: facility_type, parent: block_region)
      end
    end
  end

  def find_region_type(name)
    if dry_run?
      RegionType.new name: name
    else
      RegionType.find_by! name: name
    end
  end

  def create_region_types
    logger.info msg: "create_region_types"
    unless dry_run?
      root = RegionType.create! name: "Root", path: "Root"
      org = RegionType.create! name: "Organization", parent: root
      state = RegionType.create! name: "State", parent: org
      district = RegionType.create! name: "District", parent: state
      block = RegionType.create! name: "Block", parent: district
      _facility = RegionType.create! name: "Facility", parent: block
    end
    root
  end

  def create_region_from(parent:, region_type:, name: nil, source: nil)
    # logger.info msg: "create_region_from", parent: parent.name, type: region_type.name, name: name, source: source
    raise ArgumentError, "Provide either a name or a source" if (name && source) || (name.blank? && source.blank?)
    region_name = name || source.name
    region = DryRunRegion.new(Region.new(name: region_name, type: region_type), dry_run: dry_run?, logger: logger)
    region.set_slug
    region.source = source if source
    region.path = [parent.path, region.name_to_path_label].compact.join(".")

    if region.save_or_check_validity
      count_success(region_type)
    else
      count_invalid(region_type)
    end
    region
  end

  def count_success(region_type)
    success_counts[region_type.name] ||= 0
    success_counts[region_type.name] += 1
  end

  def count_invalid(region_type)
    invalid_counts[region_type.name] ||= 0
    invalid_counts[region_type.name] += 1
  end
end
