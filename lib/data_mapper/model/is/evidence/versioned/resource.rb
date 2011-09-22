module DataMapper::Model::Is::Evidence
  module Versioned
    module Resource
      def self.included(versioned_model)
        versioned_model.class_eval do
          extend ClassMethods

          # soft-delete versioned resources to preserve referential integrity
          #   with versions stored in related table
          property :deleted_at, DataMapper::Property::ParanoidDateTime

          before :save,   :capture_original_attributes
          after  :create, :record_create_event
          after  :update, :record_update_event
        end
      end

      # @api private
      def capture_original_attributes
        @_previous_original_attributes = original_attributes.dup.freeze
      end

      # @api private
      def record_create_event
        model.version_model.record_event(self, :create) if clean? && saved?
      end

      # @api private
      def record_update_event
        if clean? && _previous_original_attributes.any?
          # deleted_at is set on destroy by ParanoidDateTime (instead of destroying)
          event = deleted_at.nil? ? :update : :destroy
          # ParanoidDateTime sets persisted_state to Immutable,
          # so don't try to clear @_previous_original_attributes
          model.version_model.record_event(self, event)
          @_previous_original_attributes = {} if deleted_at.nil?
        end
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
