module DataMapper::Model::Is::Evidence
  module ActorTracking
    def actor_model
      Admin
    end

    def current_actor
      current_actor_stack.last
    end

    def current_actor=(actor)
      current_actor_stack << actor
    end

    def current_actor_exit
      current_actor_stack.pop
    end

    def as_actor(resource)
      self.current_actor = resource
      yield
    ensure
      self.current_actor_exit
    end

    def auditing_metadata
      thread_local[:auditing_metadata] ||= {}
    end

    def auditing_metadata=(metadata = {})
      thread_local[:auditing_metadata] = metadata
    end

  private

    def current_actor_stack
      thread_local[:current_actor_stack] ||= []
    end

    def thread_local
      Thread.current[:paper_trail_data] ||= {}
    end
  end # module ActorTracking

  extend ActorTracking
end # DataMapper::Model::Is::Evidence
