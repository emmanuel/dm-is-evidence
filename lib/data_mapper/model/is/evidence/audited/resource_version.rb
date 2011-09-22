module DataMapper::Model::Is::Evidence
  module Audited
    module ResourceVersion
      def self.included(version_model)
        version_model.extend ClassMethods

        action_model = version_model.action_model
        actor_model  = version_model.actor_model

        # TODO: update DataMapper::Association::Relationship to accept
        # :index / :unique_index options and pass them through to generated
        # child keys (eg., in belongs_to :action, pass through to :action_id)
        version_model.class_eval do
          property :action_id, Integer, :required => false, :unique_index => true

          belongs_to :action, action_model,
                     :child_key  => [:action_id],
                     :repository => action_model.default_repository_name

          has 1, :actor, actor_model,
                 :through    => :action,
                 :child_key  => [:actor_id],
                 :repository => actor_model.default_repository_name
        end
      end

      module ClassMethods
        attr_reader :action_model, :actor_model

        def record_event(resource, event, options = {})
          # TODO: set up DataMapper::Model::Is::Evidence.current_action (instead of current_actor)
          #   and store changes on Version (Action.changes -> Version.changes)
          if resource.changed_audited_properties.any?
            actor  = DataMapper::Model::Is::Evidence.current_actor
            action = action_model.create(:actor   => actor,
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
