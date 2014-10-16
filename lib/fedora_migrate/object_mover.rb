module FedoraMigrate
  class ObjectMover

    attr_accessor :source, :target

    def initialize pid, model=nil
      @source = FedoraMigrate.source.connection.find(pid)
      @target = model
    end

    def migrate
      prepare_target
      target.datastreams.keys.each do |ds|
        mover = datastream_mover(ds)
        mover.migrate
      end
    end

    private

    def datastream_mover ds
      FedoraMigrate::DatastreamMover.new( 
        source: source.datastreams[ds], 
        target: target.datastreams[ds],
        versionable: target.datastreams[ds].versionable?
      )
    end

    def prepare_target
      create_target_model if target.nil?
      target.save
    end

    def create_target_model
      afmodel = source.models.map { |m| m if m.match(/afmodel/) }.compact.first.split(/:/).last
      @target = afmodel.constantize.new(pid: source.pid.split(/:/).last)
    end

  end
  
end