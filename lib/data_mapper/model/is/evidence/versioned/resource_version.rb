module DataMapper::Model::Is::Evidence
  module Versioned
    EVENTS = %w[create update destroy]

    module ResourceVersion
      def self.included(version_model)
        version_model.extend ClassMethods

        versioned_model = version_model.versioned_model# .to_s
        raise "#{version_model}.versioned_model must be set" unless versioned_model

        class << versioned_model
          attr_accessor :version_model
        end
        versioned_model.version_model = version_model

        versioned_model.class_eval do
          attr_accessor :version

          has n, :versions, version_model,
                 :child_key  => [:resource_id],
                 :repository => version_model.default_repository_name,
                 :inverse    => :resource,
                 :constraint => :skip
        end

        version_model.class_eval do
          property :id,          DataMapper::Property::Serial
          property :resource_id, DataMapper::Property::Integer,  :index => :resource
          property :created_at,  DataMapper::Property::DateTime, :default => proc { DateTime.now }
          property :event,       DataMapper::Property::String# , :set => Versioned::EVENTS
          property :data,        DataMapper::Property::Json

          belongs_to :resource, versioned_model,
                     :child_key  => [:resource_id],
                     :repository => versioned_model.default_repository_name,
                     :inverse    => :version
        end
      end

      def reify
        data = self.data
        versioned_model = self.versioned_model
        # Ensures that lazy properties are loaded (they are present in #data)
        properties_to_load = versioned_model.properties_with_subclasses
        query = versioned_model.all(:fields => properties_to_load).query

        # WARNING: Results across schema change are undefined
        # This uses the current schema (versioned_model.properties) to load the
        # data for a historical version. The versioned model may have been
        # updated since this version was created. Fields no longer present in
        # the schema will be omitted, Properties with changed definitions will
        # pass through the version data through the current Property#load that
        # bears the same name.
        reified = versioned_model.load([ data ], query).first
        reified.persisted_state = DataMapper::Resource::State::Immutable.new(reified)
        reified.version = self
        reified
      end

      def versioned_model
        versioned_model = model.versioned_model

        if discriminator = versioned_model.properties.discriminator
          discriminator_value = data[discriminator.field.to_s]
          versioned_model = discriminator.load(discriminator_value)
        end

        versioned_model
      end

      module ClassMethods
        attr_reader :versioned_model

        def record_event(resource, event, options = {})
          version_attributes  = {
            :resource => resource,
            :event    => event,
            :data     => dump_attributes(resource),
          }.merge(options)

          create version_attributes
        end

        def dump_attributes(resource)
          # retrieve Resource#attributes keyed by field for cold storage
          # use Property#dump in order to store primitive values
          # TODO: is Property#field or Property#name more likely stable over time?
          properties = resource.__send__(:properties)
          resource.__send__(:lazy_load, properties)
          Hash[properties.map do |property|
            [property.field, property.dump(property.get(resource))]
          end]
        end
      end # module ClassMethods

    end # module ResourceVersion
  end # module Versioned
end # module DataMapper::Model::Is::Evidence
