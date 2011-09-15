module DataMapper::Model::Is::Evidence
  module Audited
    module ResourceVersion
      def self.included(model)
        model.extend ClassMethods

        action_model = model.action_model
        actor_model  = model.actor_model

        # TODO: update DataMapper::Association::Relationship to accept
        # :index / :unique_index options and pass them through to generated
        # child keys (eg., in belongs_to :action, pass through to :action_id)
        model.property :action_id, Integer, :required => false, :unique_index => true

        model.belongs_to :action, action_model,
                         :child_key  => [:action_id],
                         :repository => action_model.default_repository_name

        model.has 1, :actor, actor_model,
                     :through    => :action,
                     :child_key  => [:actor_id],
                     :repository => actor_model.default_repository_name
      end

      module ClassMethods
        attr_reader :action_model, :actor_model

        def record_event(resource, event, options = {})
          if resource.changed_audited_properties.any?
            action = action_model.create(:actor   => DataMapper::Model::Is::Evidence.current_actor,
                                         :event   => event,
                                         :changes => resource.audited_field_changes)
            super(resource, event, options.merge(:action => action))
          else
            super
          end
        end

        def version_metadata
          DataMapper::Model::Is::Evidence.auditing_metadata.merge(super)
        end
      end # module ClassMethods

    end # module ResourceVersion
  end # module Audited
end # module DataMapper::Model::Is::Evidence
