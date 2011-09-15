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
            is :an_action, :on => #{self.name}
          end
        RUBY
      end

      unless self < DataMapper::Is::Evidence::Versioned::Resource
        @versioned_on ||= DataMapper::Is::Evidence::Model.filter_properties(properties, options)

        # TODO: create version model if not already defined. something like:
        #   if !defined?(self::Version)
        #     DataMapper::Model.new :Version, self
        #     self::Version.is :a_version, of: self
        #   end
        #   @version_model = self::Version

        include DataMapper::Is::Evidence::Versioned::Resource
      end

      if audited and !(self < DataMapper::Is::Evidence::Audited::Resource)
        @audited_on  ||= DataMapper::Is::Evidence::Model.filter_properties(properties, audit_options)
        @actor_model ||= audit_options.fetch(:actor) { DataMapper::Is::Evidence.actor_model }


    # call VersionedResource::Version.is :a_version, :of => VersionedResource
    def is_a_version(options = {})
      @versioned_model ||= options[:of] or raise "expected :of option (versioned model)"
      class << @versioned_model
        attr_accessor :version_model
      end
      @versioned_model.version_model = self

      include Versioned::ResourceVersion unless self < Versioned::ResourceVersion

      if actor_model = options[:audit]
        actor_model = DataMapper::Is::Evidence.actor_model unless actor_model.kind_of?(DataMapper::Resource)
        @actor_model  = actor_model
        @action_model = options.fetch(:action) { versioned_model::Action }

        include Audited::ResourceVersion unless self < Audited::ResourceVersion
      end
    end


    # call ActorModel.is :audited_actor
        include DataMapper::Is::Evidence::Audited::Resource
      end
    end

    def is_audited_actor(options = {})
      @action_model = options.fetch(:action) { raise ArgumentError, "expected :action option" }

    # call ActorModel::Action.is :an_action
    def is_an_action(options = {})
      if audited_model = options[:on]
        @audited_model = audited_model
        @version_model = options.fetch(:version) { @audited_model::Version }

        include Audited::Action
      else
        @actor_model = options.fetch(:by) { DataMapper::Is::Evidence.actor_model }

        include Audited::AuditedAction
      end
    end


      include DataMapper::Is::Evidence::Audited::Actor
    end

    def self.filter_properties(properties, options)
      property_list  = options.fetch(:on) { properties.map { |p| p.name } }
      property_list -= options.fetch(:ignore) { [] }
      # properties.values_at(*property_list)
      property_list.map { |name| properties[name] }
    end
  end # module Model
end # module DataMapper::Is::Evidence

DataMapper::Model.send(:include, DataMapper::Is::Evidence::Model)
