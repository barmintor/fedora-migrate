module FedoraMigrate
  class DatastreamMover < Mover

    attr_accessor :versionable

    def post_initialize
      raise FedoraMigrate::Errors::MigrationError, "You must supply a target" if @target.nil?
      @key = options[:ds_key].to_s
    end

    def source
      @source.datastreams[@key]
    end

    def target
      @target.attached_files[@key]
    end

    def versionable?
      versionable.nil? ? target_versionable? : versionable
    end

    def target_versionable?
      if target.respond_to?(:versionable?)
        target.versionable?
      else
        false
      end
    end

    def migrate
      before_datastream_migration
      migrate_datastream
      after_datastream_migration
      super
    end

    private

    def migrate_datastream
      if versionable?
        migrate_versions
      else
        migrate_current
      end
    end

    # Reload the target, otherwise the checksum is nil
    def migrate_current
      migrate_content
      target.reload if report.last.success?
    end

    # Rubydora stores the versions array as the most recent first. We explicitly sort them according to createDate
    def migrate_versions
      source.versions.sort { |a,b| a.createDate <=> b.createDate }.each do |version|
        migrate_content(version)
        target.create_version if report.last.success? && !application_creates_versions?
      end
    end

    def migrate_content datastream=nil
      datastream ||= source
      report << FedoraMigrate::ContentMover.new(datastream, target).migrate
    end

  end

end
