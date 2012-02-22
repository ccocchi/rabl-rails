module RablFastJson
  class CompiledTemplate

    attr_accessor :source

    delegate :[], :[]=, :to => :source

    def initialize
      @source = {}
    end

    #
    # def render(data = nil)
    #   output = {}
    #   @data = data if data
    #
    #   return render_collection if @data.respond_to?(:each)
    #
    #   @template.each_pair { |key, value|
    #     out = case value
    #     when Symbol
    #       @data.send(value)
    #     end
    #     output[key] = out
    #   }
    #   output
    # end
    #
    # def render_collection
    #   output = []
    #   @data.each { |o|
    #     object = {}
    #     @template.each_pair { |key, value|
    #       out = case value
    #       when Symbol
    #         o.send(value)
    #       end
    #       object[key] = out
    #     }
    #     output << object
    #   }
    #   output
    # end
  end
end