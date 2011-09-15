module DataMapper::Model::Is::Evidence
  module Versioned
    module Resource
      def self.included(model)
        model.extend ClassMethods

        # soft-delete versioned resources to preserve referential integrity
        model.property :deleted_at, DataMapper::Property::ParanoidDateTime

        model.before :save do
          @_previous_original_attributes = original_attributes.dup.freeze
        end

        model.after :create do
          model::Version.record_event(self, :create) if clean? && saved?
        end

        model.after :update do
          if clean? && _previous_original_attributes.any?
            # deleted_at is set on destroy by ParanoidDateTime (instead of destroying)
            event = deleted_at.nil? ? :update : :destroy
            # ParanoidDateTime sets persisted_state to Immutable,
            # so don't try to clear @_previous_original_attributes
            model::Version.record_event(self, event)
            @_previous_original_attributes = {} if deleted_at.nil?
          end
        end

        # ParanoidDateTime causes #destroy calls to become updates,
        # rendering this superfluous:
        # model.after :destroy do
        #   model::Version.record_event(self, :destroy) if clean?
        # end
      end

      # @api private
      def _previous_original_attributes
        original_attributes = self.original_attributes
        if original_attributes.any?
          original_attributes
        else
          @_previous_original_attributes ||= {}
        end
      end

      # @api public
      def attribute_changes
        Hash[_previous_original_attributes.map do |property, value|
          [ property, [ value, property.get!(self) ] ]
        end]
      end

      module ClassMethods
        attr_reader :versioned_on
      end # module ClassMethods

    end # module Resource
  end # module Versioned
end # module DataMapper::Model::Is::Evidence
