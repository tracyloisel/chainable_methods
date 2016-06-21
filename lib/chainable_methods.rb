require "chainable_methods/version"

# easier shortcut
def CM(initial_state, context: ChainableMethods::Nil, pass_through: false)
  ChainableMethods::Link.new(initial_state, context: context, pass_through: pass_through)
end

module ChainableMethods
  # TODO placeholder context to always delegate method missing to the state object
  module Nil; end

  def self.included(base)
    base.extend(self)
    begin
      # this way the module doesn't have to declare all methods as class methods
      base.extend(base) if base.kind_of?(Module)
    rescue TypeError
      # wrong argument type Class (expected Module)
    end
  end

  def chain_from(initial_state = nil, context: self, pass_through: false)
    initial_state = self if initial_state.nil?
    ChainableMethods::Link.new(initial_state, context: context, pass_through: pass_through)
  end

  class Link
    def initialize(object, context:, pass_through: false)
      @state   = object
      @context = context
      @pass_through = pass_through
    end

    def chain(&block)
      new_state = block.call(@state)
      if @pass_through
        new_state
      else
        ChainableMethods::Link.new( new_state, context: @context, pass_through: @pass_through)
      end
    end

    def method_missing(method_name, *args, &block)
      local_response   = @state.respond_to?(method_name)
      context_response = @context.respond_to?(method_name)

      # if the state itself has the means to respond, delegate to it
      # but if the context has the behavior, it has priority over the delegation
      new_state = if local_response && !context_response
                    @state.send(method_name, *args, &block)
                  else
                    @context.send(method_name, *args.unshift(@state), &block)
                  end

      if @pass_through
        new_state
      else
        ChainableMethods::Link.new( new_state, context: @context, pass_through: @pass_through )
      end
    end

    def unwrap
      @state
    end
  end
end
