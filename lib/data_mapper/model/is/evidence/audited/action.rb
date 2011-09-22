module DataMapper::Model::Is::Evidence
  module Audited
    module Action
      def self.included(action_model)
        action_model.extend ClassMethods

        version_model   = action_model.version_model
        versioned_model = version_model.versioned_model

        action_model.class_eval do
          has 1, :version, version_model,
                 :child_key  => [:action_id],
                 :repository => version_model.default_repository_name

          has 1, :resource, versioned_model,
                 :through    => :version,
                 :child_key  => [:resource_id],
                 :repository => versioned_model.default_repository_name
        end
      end

      # TODO: specifying this correctly (as a relationship) didn't work
      def target_resource
        model.version_model.first(:action => self).resource
      end

      module ClassMethods
        attr_reader :audited_model, :version_model
        # TODO: look into replacing attr_reader with dynamic lookup from the relationship
        # def audited_model
        #   @audited_model ||= relationships[:resource].target_model
        # end
        # 
        # def version_model
        #   @version_model ||= relationships[:version].target_model
        # end
      end
    end # module Action
  end # module Audited
end # module DataMapper::Model::Is::Evidence
