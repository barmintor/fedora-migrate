module FedoraMigrate
  module MigrationOptions

    attr_accessor :options, :conversions

    def conversion_options
      self.conversions = options.nil? ? [] : [options[:convert]].flatten      
    end

    def forced?
      option_true?(:force)
    end

    def not_forced?
      !forced?
    end

    def application_creates_versions?
      option_true?(:application_creates_versions)
    end
    
    private
    
    def option_true?(name)
      !!(options && options[name])
    end

  end
end
