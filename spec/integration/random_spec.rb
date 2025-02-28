# frozen_string_literal: true

require 'dry/effects/provider'

RSpec.describe 'handling random' do
  let(:handler) { Dry::Effects::Frame.new(provider) }

  include Dry::Effects.Random

  context 'with custom provider' do
    let(:provider) do
      Class.new(Dry::Effects::Provider[:random]) {
        attr_reader :seed

        def rand(modulo)
          n = seed % modulo
          shift
          n
        end

        def output(result)
          result
        end

        def call(stack, seed = @seed)
          @seed = seed
          super(stack)
        end

        private

        def shift
          @seed = seed % 1000 + seed / 1000
        end
      }.new.freeze
    end

    context 'seed = 10' do
      let(:seed) { 121 }

      example 'getting random values' do
        result = handler.(seed) do
          [rand(5), rand(9)]
        end

        expect(result).to eql([1, 4])
      end
    end
  end

  context 'with default provider' do
    let(:handler) { Dry::Effects[:random] }

    example 'producing random values' do
      result = handler.() do
        Array.new(100) { rand(10) }
      end

      expect(result.max).to be < 10
    end
  end
end
