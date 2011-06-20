module DataMapper::Is::Evidence
  module Versioned
    EVENTS = %w[create update destroy]

    module ResourceVersion
      def self.included(model)
        model.extend ClassMethods

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
        if discriminator = versioned_model.properties.discriminator
          discriminator_value = data[discriminator.field.to_s]
          versioned_model = discriminator.load(discriminator_value)
        end
        # TODO: use :fields => versioned_model.properties_with_subclasses
        # to load properties defined for STI descendants but not the base model
        query = versioned_model.all.query

        # WARNING: Results across schema change are undefined
        # This uses the current schema (versioned_model.properties) to load the
        # data for a historical version. The versioned model may have been
        # updated since this version was created. Fields no longer present in
        # the schema will be omitted, Properties with changed definitions will
        # pass through the version data through the current Property#load that
        # bears the same name.
        reified = versioned_model.load([ data ], query).first
        reified.persisted_state = DataMapper::Resource::State::Immutable.new(reified)
        reified
      end

      module ClassMethods
        attr_reader :versioned_model

        def record_event(resource, event, options = {})
          # retrieve Resource#attributes keyed by field for cold storage
          # TODO: is Property#field or Property#name more likely stable over time?
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
