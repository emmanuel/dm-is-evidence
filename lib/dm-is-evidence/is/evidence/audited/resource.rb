module DataMapper::Is::Evidence
  module Audited
    module Resource
      def self.included(model)
        model.extend ClassMethods

        # configure model.version_class as an audited version (belongs_to :action)
        model::Version.is :a_version, of: model, audit: model.actor_model
      end

      # Specifying this as a relationship didn't work, but this does
      def logged_actions
        versions.actions
      end

      # Specifying this as a relationship didn't work, but this does
      def logged_actors
        audited_actions.actors
      end

      module ClassMethods
        attr_reader :actor_model, :audited_on
      end # module ClassMethods
    end # module Resource
  end # module Audited
end # module DataMapper::Is::Evidence
