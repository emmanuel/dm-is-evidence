module DataMapper::Is::Evidence
  module Versioned
    EVENTS = %w[create update destroy]

    module ResourceVersion
      def self.included(model)
        model.extend ClassMethods
        # model.__send__ :include, Immutable

        versioned_model = model.versioned_model# .to_s
        raise "#{model}.versioned_model must be set" unless versioned_model

        model.property :resource_id, DataMapper::Property::Integer,         :key => true, :index => :resource
        model.property :created_at,  DataMapper::Property::CreatedDateTime, :key => true
        model.property :event,       DataMapper::Property::String, :set => Versioned::EVENTS
        model.property :data,        DataMapper::Property::Json

        model.belongs_to :resource, versioned_model,
                         :child_key  => [:resource_id],
                         :repository => versioned_model.default_repository_name
      end

      def reify
        data = self.data

        versioned_model = model.versioned_model
        discriminator   = versioned_model.properties.discriminator
        versioned_model = discriminator.load(data[discriminator.field.to_s]) if discriminator
        # WARNING: this uses the current schema (versioned_model.properties) to load the data.
        # Fields no longer present in the schema will be omitted, changed Property
        # will pass through the current Property#load that bears the name, so results will vary
        query           = versioned_model.all.query

        reified = versioned_model.load([ data ], query).first
        reified.persisted_state = DataMapper::Resource::State::Immutable.new(reified)
        reified
      end

      module ClassMethods
        attr_reader :versioned_model

        def record_event(resource, event, options = {})
          resource_attributes = resource.attributes(:field)
          version_attributes  = {
            :resource => resource,
            :event    => event,
            :data     => resource_attributes
          }.merge(options)

          create version_attributes
        end

      end # module ClassMethods
    end # module ResourceVersion
  end # module Versioned
end # module DataMapper::Is::Evidence
