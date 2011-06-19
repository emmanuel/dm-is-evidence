module DataMapper::Is::Evidence
  # extend your custom version class with this, then call Class.versions
  # to configure versioning/auditing of the target model (first arg)
  module Action
    def is_an_action(options = {})
      if audited_model = options[:on]
        @audited_model = audited_model
        @version_model = options.fetch(:version) { @audited_model::Version }

        include Audited::Action
      else
        @actor_model = options.fetch(:by) { DataMapper::Is::Evidence.actor_model }
        include Audited::AuditedAction
      end
    end

    DataMapper::Model.append_extensions self
  end # module Action
end # module DataMapper::Is::Evidence
