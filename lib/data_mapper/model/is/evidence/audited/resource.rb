module DataMapper::Model::Is::Evidence
  module Audited
    module Resource
      def self.included(audited_model)
        audited_model.extend ClassMethods

        # configure audited_model.version_model as an audited version (belongs_to :action)
        audited_model::Version.is :a_version,
                                  :of    => audited_model,
                                  :audit => audited_model.actor_model
      end

      def changed_audited_properties
        _previous_original_attributes.keys & model.audited_on
      end

      def audited_field_changes
        # dump by field name; that's how model.load works (in ResourceVersion#reify)
        Hash[audited_property_changes.map do |property, values|
          [property.field, values]
        end]
      end

      def audited_property_changes
        DataMapper::Ext::Hash.only(attribute_changes, *model.audited_on)
      end

      # Specifying this as a relationship didn't work, but this does
      def logged_actions
        versions.actions
      end

      # Specifying this as a relationship didn't work, but this does
      def logged_actors
        audited_actions.actors
      end

      module ClassMethods
        attr_reader :actor_model, :audited_on
      end # module ClassMethods

    end # module Resource
  end # module Audited
end # module DataMapper::Model::Is::Evidence
