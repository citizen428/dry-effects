# frozen_string_literal: true

require 'dry/initializer'

module Dry
  module Effects
    module Initializer
      # @api private
      module DefineWithHook
        # @api private
        def param(*)
          super.tap do
            @params_arity = nil
            __define_with__
          end
        end

        # @api private
        def option(*)
          super.tap do
            __define_with__ unless method_defined?(:with)
            @has_options = true
          end
        end

        # @api private
        def params_arity
          @params_arity ||= begin
            dry_initializer
              .definitions
              .reject { |_, d| d.option }
              .size
          end
        end

        # @api private
        def options?
          return @has_options if defined? @has_options
          @has_options = false
        end

        # @api private
        def __define_with__
          seq_names = dry_initializer
            .definitions
            .reject { |_, d| d.option }
            .keys
            .join(', ')

          seq_names << ', ' unless seq_names.empty?

          undef_method(:with) if method_defined?(:with)

          class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            def with(new_options = EMPTY_HASH)
              if new_options.empty?
                self
              else
                self.class.new(#{seq_names}options.merge(new_options))
              end
            end
          RUBY
        end
      end

      # @api private
      def self.extended(base)
        base.extend(::Dry::Initializer)
        base.extend(DefineWithHook)
        base.include(InstanceMethods)
      end

      # @api private
      module InstanceMethods
        # Instance options
        #
        # @return [Hash]
        #
        # @api public
        def options
          @__options__ ||= self.class.dry_initializer.definitions.values.each_with_object({}) do |item, obj|
            obj[item.target] = instance_variable_get(item.ivar)
          end
        end

        define_method(:class, Kernel.instance_method(:class))
        define_method(:instance_variable_get, Kernel.instance_method(:instance_variable_get))

        # This makes sure we memoize options before an object becomes frozen
        #
        # @api public
        def freeze
          options
          super
        end
      end
    end
  end
end
