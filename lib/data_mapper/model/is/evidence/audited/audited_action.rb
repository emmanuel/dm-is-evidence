module DataMapper::Model::Is::Evidence
  module Audited
    module AuditedAction
      def self.included(action_model)
        action_model.extend ClassMethods

        actor_model = action_model.actor_model

        action_model.class_eval do
          property :id,         DataMapper::Property::Serial
          # specifying actor_id via the belongs_to call automatically adds an index
          property :actor_id,   DataMapper::Property::Integer,       :index => :actor
          property :type,       DataMapper::Property::Discriminator# , :index => :type
          property :event,      DataMapper::Property::String
          property :changes,    DataMapper::Property::Json
          property :created_at, DataMapper::Property::DateTime, :default => proc { DateTime.now }

          belongs_to :actor, actor_model,
                     :child_key  => [:actor_id],
                     :repository => actor_model.default_repository_name
        end
      end

      module ClassMethods
        attr_reader :actor_model
      end

    end # module AuditedAction
  end # module Audited
end # module DataMapper::Model::Is::Evidence
