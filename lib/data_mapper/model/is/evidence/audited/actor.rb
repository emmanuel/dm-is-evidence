module DataMapper::Model::Is::Evidence
  module Audited
    module Actor
      def self.included(actor_model)
        actor_model.extend ClassMethods

        action_model = actor_model.action_model

        actor_model.class_eval do
          has n, :audited_actions, action_model,
                 :child_key  => [:actor_id],
                 :repository => action_model.default_repository_name
        end
      end

      # TODO: figure out how to OUTER JOIN all the action_model.subclasses to
      # retrieve all affected versions &/or resources (through versions) in one query
      # OR just live with one query per versioned model & sorting in Ruby.
      def audited_versions
        action_base_model = model.action_model
        # poor man's UNION across models/tables/types :(
        mixed_list = []
        action_base_model.descendants.each do |sti_model|
          mixed_list.concat sti_model.all(:actor => self).versions.to_a
        end
        mixed_list.sort { |a, b| a.created_at <=> b.created_at }
      end

      def audited_resources
        action_base_model = model.action_model
        # poor man's UNION across models/tables/types :(
        mixed_list = []
        action_base_model.descendants.each do |sti_model|
          mixed_list.concat sti_model.all(:actor => self).versions.resources.to_a
        end
        mixed_list.sort { |a, b| a.created_at <=> b.created_at }
      end

      module ClassMethods
        attr_reader :action_model
      end
    end # module Actor
  end # module Audited
end # module DataMapper::Model::Is::Evidence
