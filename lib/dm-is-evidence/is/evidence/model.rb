module DataMapper::Is::Evidence
  module Model
    def is_versioned(options = {})
      # TODO: deal with inheritance of these class ivars
      #   (@versioned_on, @audited_on, @actor_model)
      properties    = self.properties
      audited       = options.fetch(:audited, false)
      audit_options = audited || {}

      if !defined?(self::Action) and action_base_model = audit_options.fetch(:via, nil)
        # const_set :Action, Class.new(action_base_model)
        # self::Action.is :an_action, on: self
        # ^ this fails because DescendantSet is indexed by name, and the new
        # dynamic subclass inherits from action_base_model before the constant
        # is set, and therefore before the new model has a non-nil model.name.
        self.module_eval <<-RUBY, __FILE__, __LINE__ + 1
          class Action < #{action_base_model.name}
            is :an_action, on: #{self.name}
          end
        RUBY
      end

      unless self < DataMapper::IsEvidence::Versioned::Resource
        @versioned_on ||= DataMapper::IsEvidence::Model.filter_properties(properties, options)

        # TODO: create version model if not already defined. something like:
        #   if !defined?(self::Version)
        #     DataMapper::Model.new :Version, self
        #     self::Version.is :a_version, of: self
        #   end
        #   @version_model = self::Version

        include DataMapper::IsEvidence::Versioned::Resource
      end

      if audited and !(self < DataMapper::IsEvidence::Audited::Resource)
        @audited_on  ||= DataMapper::IsEvidence::Model.filter_properties(properties, audit_options)
        @actor_model ||= audit_options.fetch(:actor) { DataMapper::IsEvidence.actor_model }

        include DataMapper::IsEvidence::Audited::Resource
      end
    end

    def is_audited_actor(options = {})
      @action_model = options.fetch(:action) { raise ArgumentError, "expected :action option" }

      include DataMapper::IsEvidence::Audited::Actor
    end

    def self.filter_properties(properties, options)
      property_list  = options.fetch(:on) { properties.map { |p| p.name } }
      property_list -= options.fetch(:ignore) { [] }
      property_list.map { |name| properties[name] }
    end
  end # module Model
end # module DataMapper::IsEvidence

DataMapper::Model.send(:include, DataMapper::IsEvidence::Model)
