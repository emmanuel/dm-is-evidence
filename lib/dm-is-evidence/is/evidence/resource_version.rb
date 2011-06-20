module DataMapper::Is::Evidence
  # extend your custom version class with this, then call Class.versions
  # to configure versioning/auditing of the target model (first arg)
  module ResourceVersion
    def is_a_version(options = {})
      @versioned_model ||= options[:of] or raise "expected :of option (versioned model)"

      include Versioned::ResourceVersion unless self < Versioned::ResourceVersion

      if actor_model = options[:audit]
        actor_model = DataMapper::Is::Evidence.actor_model unless actor_model.kind_of?(DataMapper::Resource)
        @actor_model  = actor_model
        @action_model = options.fetch(:action) { versioned_model::Action }

        include Audited::ResourceVersion unless self < Audited::ResourceVersion
      end
    end

    DataMapper::Model.append_extensions self
  end # module ResourceVersion
end # module DataMapper::Is::Evidence
