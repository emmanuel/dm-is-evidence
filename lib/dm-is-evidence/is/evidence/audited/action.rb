module DataMapper::Is::Evidence
  module Audited
    module Action
      def self.included(model)
        model.extend ClassMethods

        version_model   = model.version_model
        versioned_model = version_model.versioned_model

        model.has 1, :version,
                     child_key:  :action_id,
                     model:      version_model,
                     repository: version_model.default_repository_name

        model.has 1, :resource,
                     through:    :version,
                     child_key:  :resource_id,
                     model:      versioned_model,
                     repository: versioned_model.default_repository_name
      end

      # TODO: specifying this correctly (as a relationship) doesn't work
      def target_resource
        model.version_model.first(action: self).resource
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
    end # module ResourceAudit
  end # module Audited
end # module DataMapper::Is::Evidence
