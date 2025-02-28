# frozen_string_literal: true

require 'concurrent/map'
require 'dry/effects/inflector'
require 'dry/effects/handler'

module Dry
  module Effects
    default = %i[
      cache current_time random resolve defer
      state interrupt cmp retry fork parallel
      async implicit env lock reader timestamp
      timeout
    ]

    effect_modules = ::Concurrent::Map.new

    default.each do |key|
      class_name = Inflector.camelize(key)

      if ::File.exist?("#{__dir__}/effects/#{key}.rb")
        effects.register(key, memoize: true) do
          require "dry/effects/effects/#{key}"
          Effects.const_get(Inflector.camelize(key))
        end

        singleton_class.class_eval do
          define_method(class_name) do |*args|
            effect_modules.fetch_or_store([key, args]) do
              ::Dry::Effects.effects[key].new(*args).freeze
            end
          end
        end
      end

      if ::File.exists?("#{__dir__}/providers/#{key}.rb")
        providers.register(key, memoize: true) do
          require "dry/effects/providers/#{key}"
          Providers.const_get(Inflector.camelize(key))
        end

        Handler.singleton_class.send(:define_method, class_name) do |*args|
          ::Dry::Effects.providers[key].mixin(*args)
        end
      end
    end
  end
end
