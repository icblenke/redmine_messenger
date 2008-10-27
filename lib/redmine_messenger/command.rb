module RedmineMessenger
  class Command

    attr_reader :group, :command, :method, :options

    def initialize(command, options = {})
      @group = :general
      @command = command.to_sym
      @method = command.to_sym    
      @options = options
      @options[:pattern] ||= Regexp.new("^#{command.to_s}")
      @parameters = []
    end
    
    def receive(from, body)
      params = {}
      tokens = body.split(/\s+/)
      tokens.shift if tokens[0] == @command.to_s

      @parameters.each do |param|
        if tokens.empty? and param.options[:required]
          return false
        elsif param.options[:type] == :integer
          params[param.name.to_sym] = Integer(tokens.shift)
        else
          params[param.name.to_sym] = tokens.shift
        end
      end

      unless tokens.empty?
        params[:other] = tokens.join(" ")
      end

      [from, params]
    end
        
    def group(group = nil)
      if group.nil?
        @group 
      else
        @group = group       
      end
    end
    
    def method(method = nil)
      if method.nil?
        @method
      else
        @method = method
      end
    end
    
    def param(name, options = {})
      @parameters << Param.new(name, options)
    end
       
    def to_s
      responce = @command.to_s
      unless @parameters.empty?
        params_names = []
        @parameters.each do |param|
          params_names << param.name.to_s
        end
        responce << " <" << params_names.join(",") << ">"
      end
      responce
    end
    
  end
  
  class Param

    attr_reader :name, :options
    
    def initialize(name, options)
      @name = name
      @options = { :required => true, :type => :string }
      @options.merge!(options)      
    end

  end
end