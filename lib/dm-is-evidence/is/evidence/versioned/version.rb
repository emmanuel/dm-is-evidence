module DataMapper::Is::Evidence
  module Versioned
    EVENTS = %w[create update destroy]

    module Version
      def self.included(model)
        model.extend ClassMethods
        # model.__send__ :include, Immutable

        versioned_model = model.versioned_model# .to_s
        raise "#{model}.versioned_model must be set" unless versioned_model

        model.property :resource_id, DataMapper::Property::Integer,         key: true, index: :resource
        model.property :created_at,  DataMapper::Property::CreatedDateTime, key: true
        model.property :event,       DataMapper::Property::String,  set: Versioned::EVENTS
        model.property :data,        DataMapper::Property::Json

        model.belongs_to :resource,
                         child_key: :resource_id,
                         repository: versioned_model.default_repository_name,
                         model:      versioned_model
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
          version_attributes = merge_version_metadata(resource: resource,
                                                      event:    event,
                                                      data:     resource_attributes)
          create version_attributes.merge(options)
        end

        # @api private
        # TODO: consider supporting block (yield resource) & symbol (send) values
        def merge_version_metadata(data = {})
          version_metadata.merge(data)
        end

        # override ResourceVersionClass.version_metadata to provide additional
        # attributes to be passed to the ResourceVersionClass.create call
        # 
        # @api public
        def version_metadata
          {}
        end
      end # module ClassMethods
    end # module ResourceVersion
  end # module Versioned
end # module DataMapper::Is::Evidence
