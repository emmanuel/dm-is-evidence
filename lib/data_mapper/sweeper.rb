module DataMapper

  # DataMapper::Sweeper provides an observer to model changes that have access
  # to the controller invoking the changes.
  #
  # The api for DataMapper::Sweeper is similar to DataMapper::Observer, but
  # there is one important difference: in DataMapper::Observer .before and
  # .after blocks are evaluated in the context of the resource instance.
  # However, DataMapper::Sweeper .before and .after blocks are evaluated in the
  # context of an instance of your Sweeper class, and missing methods are
  # delegated to the controller.
  #
  #   _______________________________________
  #  / See the comment block at the end of   \
  #  | this file for a discussion about this |
  #  \ api difference                        /
  #   ---------------------------------------
  #          \   ^__^
  #           \  (oo)\_______
  #              (__)\       )\/\
  #                  ||----w |
  #                  ||     ||
  #
  #     class PageSweeper
  #       include DataMapper::Sweeper
  #       observe Page
  #
  #       after(:update) do
  #         # Because our block here is evaluated in the context of a PageSweeper
  #         # instance, we can call helper methods in this model.
  #         expire_cache_for resource
  #       end
  #
  #       after(:destroy) do
  #         expire_cache_for resource
  #       end
  #
  #     private
  #       def expire_cache_for(page)
  #         # Calls to expire_page and page_path are both delegated to the controller
  #         expire_page(page_path(page))
  #       end
  #     end
  #
  #
  # The instance in our blocks has two special methods:
  # controller::  An instance of the controller processing the request when
  #               the change happens. Gives us access to rails expire helpers,
  #               named routes, and url generation. Direct access shouldn't be
  #               needed as methods missing from the sweeper class are
  #               delegated to this controller.
  # resource::    The instance of the observed model. Unlike with
  #               DataMapper::Observer, access to the resource must be explicit
  #               as +self+ refers to the sweeper class as opposed to the
  #               observed resource.
  #
  # WARNING: Although there is an attempt to make this thread-safe, the thread-
  #          safety of this Sweeper has not been verified or tested at all!
  module Sweeper
    extend ActiveSupport::Concern

    attr_accessor :resource

    def controller
      self.class.controller
    end

    # Delegate missing methods to the controller. This helps a bunch for named
    # route calls, but also for methods like expire_page and friends...
    def method_missing(method, *arguments, &block)
      return if controller.nil?
      if controller.respond_to?(method, true)
        controller.__send__(method, *arguments, &block)
      else
        super
      end
    end

    module ClassMethods

      attr_accessor :observing

      # Assign an Array of Class names to watch.
      #   observe User, Article, Topic
      def observe(*args)
        self.observing = args
      end

      # Add a callback to the sweeper.
      # See DataMapper::Sweeper documentation for examples of use.
      #
      # @api public
      def before(argument, &block)
        # This hack allows us to adhere to two apis:
        # * if ApplicationController === argument, then we are acting as the around_filter,
        # * otherwise, we are acting as our own api of sweepers.
        if ApplicationController === argument
          around_filter_before(argument)
        else
          observing_before(argument, &block)
        end
      end

      # Add a callback to the sweeper.
      # See DataMapper::Sweeper documentation for examples of use.
      #
      # @api public
      def after(argument, &block)
        if ApplicationController === argument
          around_filter_after(argument)
        else
          observing_after(argument, &block)
        end
      end

      def controller
        Thread.current[controller_id]
      end

    private

      def controller=(controller)
        Thread.current[controller_id] = controller
      end

      def controller_id
        :"sweeper_#{self.hash}"
      end

      # The before method used as the around_filter callback
      def around_filter_before(controller)
        self.controller = controller
        true # #before around_filter method from sweeper should always return true
      end

      # The after method used as the around_filter callback
      def around_filter_after(controller)
        # Clean up, so that the controller can be collected after this request
        self.controller = nil
      end

      # The before method used as our sweeper callback
      def observing_before(sym, &block)
        self.observing.each do |klass|
          sweeper_klass = self
          # These callbacks (from DataMapper::Model::Hook) do an instance_eval
          # puting the block in the context of our observed resource. This
          # eliminates any possibity of giving the block access to the
          # controller. Here, we solve that by doing our own instance_eval.
          #
          # There is a discussion about the api difference at the bottom of this file.
          #
          # Read this for more information about this issue with instance_eval:
          # http://www.dcmanges.com/blog/ruby-dsls-instance-eval-with-delegation
          klass.before(sym.to_sym) do
            sweeper = sweeper_klass.new
            sweeper.resource = self
            # Fight instance_eval with instance_eval for great justice
            sweeper.instance_eval &block
          end
        end
      end

      # The after method used as our sweeper callback.
      #
      # For notes about implementation
      # @see #observing_before
      def observing_after(sym, &block)
        self.observing.each do |klass|
          sweeper_klass = self
          klass.after(sym.to_sym) do
            sweeper = sweeper_klass.new
            sweeper.resource = self
            # Fight instance_eval with instance_eval for great justice
            sweeper.instance_eval &block
          end
        end
      end

    end
  end
end



module ActionController #:nodoc:
  module Caching
    module Sweeping
      extend ActiveSupport::Concern

      module ClassMethods #:nodoc:
        # This replaces rails cache_sweeper helper for controllers.
        #
        # The rails version expects sweepers to be an
        # ActionController::Caching::Sweeper which is only defined if ActiveRecord
        # and ActiveRecord::Observer exists. Furthermore, it is assumed to be a
        # Singleton. We could overcome the singleton problem by defining
        # DataMapper::Sweeper::ClassMethods#instance to return self, but that would
        # not overcome the fact that the original cache_sweeper method expects the
        # sweeper class to be #is_a? ActionController::Caching::Sweeper.
        #
        # This also adds the :if => perform_caching check here.
        #
        # This should be in dm-rails, but for the moment, here's how to include
        # in an initializer.
        #
        #     require_dependency 'data_mapper/sweeper'
        #     Rails.configuration.to_prepare do
        #       ActionController::Base.instance_eval {
        #         include ActionController::Caching::Sweeping
        #       }
        #     end
        def cache_sweeper(*sweepers)
          configuration = sweepers.extract_options!

          sweepers.each do |sweeper|
            sweeper_klass = (sweeper.is_a?(Symbol) ? Object.const_get(sweeper.to_s.classify) : sweeper)
            around_filter(sweeper_klass, :only => configuration[:only], :if => proc { perform_caching })
          end
        end
      end
    end
  end
end

=begin

On the use of instance_eval and API difference from DataMapper::Observer
and other DataMapper callbacks.

For reference, the implementation (that this is modeled after) from
DataMapper::Observer is:

    def before(sym, &block)
      self.observing.each do |klass|
        klass.before(sym.to_sym, &block)
      end
    end

In this version, when we use before in our sweeper:

    before(:update) do
      # +self+ here refers to the resource.
      # There is no way to access the controller.
      # There is also no way to access helper methods in our sweeper class.
    end

The issue could be resolved by recalling the block like this:

    def before(sym, &block)
      self.observing.each do |klass|
        klass.before(sym.to_sym) do
          block.call self
        end
      end
    end

In this version, when we use before in our sweeper:

    before(:update) do |resource|
      # +self+ here refers to our sweeper class.
      # We can access +resource+ from our block argument.
      # And we can access the controller with the +controller+ method.
      # However, delegating methods to the controller would mean defining
      # method_missing on the sweeper class which would be weird.
      # We can call helpers in our sweeper class if we define them on the class.
    end

So, instead we create an instance of the sweeper class to run our block in.

    def before(sym, &block)
      self.observing.each do |klass|
        sweeper_klass = self
        klass.before(sym.to_sym) do
          sweeper = sweeper_klass.new
          sweeper.resource = self
          sweeper.instance_eval &block
        end
      end
    end

In this version, when we use before in our sweeper:

    before(:update) do
      # +self+ here refers to an instance of our sweeper class.
      # Which has a +resource+ method, and a +controller+ method.
      # This allows us to define helper methods in our class, and it also
      # allows us to delegate unknown method calls to the controller.
    end

Read this for more information about this issue with instance_eval:
http://www.dcmanges.com/blog/ruby-dsls-instance-eval-with-delegation

=end