module DataMapper::Is::Evidence
  module Audited
    module AuditedAction
      def self.included(model)
        model.extend ClassMethods

        actor_model   = model.actor_model

        model.property :id,         DataMapper::Property::Serial
        # specifying actor_id via the belongs_to call automatically adds an index
        model.property :actor_id,   DataMapper::Property::Integer,       :index => :actor
        model.property :type,       DataMapper::Property::Discriminator# , :index => :type
        model.property :event,      DataMapper::Property::String
        model.property :changes,    DataMapper::Property::Json
        model.property :created_at, DataMapper::Property::CreatedDateTime

        model.belongs_to :actor, actor_model,
                         :child_key  => [:actor_id],
                         :repository => actor_model.default_repository_name
      end

      module ClassMethods
        attr_reader :actor_model
      end

    end # module AuditedAction
  end # module Audited
end # module DataMapper::Is::Evidence
