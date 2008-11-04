module RedmineMessenger

  # Definition of registered command. This class is block parameter of <tt>RedmineMessenger::Base#register_hander</tt> method.
  class Command

    attr_reader :group, :command, :method, :options

    # Create command with given +command_name+.
    # Additional +options+ is <tt>:pattern</tt> which must match to the message body if handler should be invoke.
    def initialize(command_name, options = {})
      @group = :general
      @command = command_name.to_sym
      @method = command_name.to_sym    
      @options = options
      @options[:pattern] ||= Regexp.new("^#{command_name.to_s}\\b")
      @parameters = []
    end

    # Returns param array for given body. False if parameters are incorrect.    
    def params_for_message(message_body)
      params = {}
      tokens = message_body.split(/\s+/)
      
      tokens.shift if tokens[0] == @command.to_s

      @parameters.each do |param|
        if tokens.empty? and param.options[:required]
          return false
        elsif param.options[:greedy]
          params[param.name.to_sym] = param.value_to_type(tokens.join(" "))
          tokens = []
        elsif param.value_to_type?(tokens[0])
          params[param.name.to_sym] = param.value_to_type(tokens.shift)
        elsif not (param.value_to_type?(tokens[0]) and param.options[:required])
          params[param.name.to_sym] = nil
        else
          return false
        end
      end

      unless tokens.empty?
        params[:other] = tokens.join(" ")
      end

      params
    end
       
    # Set or get group, default is :general.
    def group(group = nil)
      if group.nil?
        @group 
      else
        @group = group       
      end
    end
    
    # Set or get method, default is <tt>command_name</tt>.
    def method(method = nil)
      if method.nil?
        @method
      else
        @method = method
      end
    end
    
    # Add new param (see <tt>Param</tt>).
    def param(name, options = {})
      @parameters << Param.new(name, options)
    end

    # Returns command name and all its parameters.
    def to_s
      unless @command_to_string
        @command_to_string = @command.to_s
        unless @parameters.empty?
          params_names = []
          @parameters.each do |param|
            name = param.name.to_s
            name << "?" unless param.options[:required]
            #name << "*" if param.options[:greedy]
            params_names << name
          end
          @command_to_string << " <" << params_names.join(",") << ">"
        end
      end
      @command_to_string
    end
    
  end
  
  # Definition of command's parameter (see <tt>Command.param</tt>).
  class Param

    attr_reader :name, :options
    
    # Create param with given +name+.
    # Additional +options+ are <tt>:required</tt> (true by default), <tt>:greedy</tt> (false by default, takes all command string if true) and <tt>:type</tt> (:string by default, others are :integer, :float).
    def initialize(name, options)
      @name = name
      @options = { :required => true, :type => :string, :greedy => false }
      @options.merge!(options)      
    end

    # Check if value has proper type.
    def value_to_type?(value)
      if @options[:type] == :integer
        /\d+/ =~ value
      elsif @options[:type] == :float
        /\d+(\.\d+)?/ =~ value
      else
        true
      end
    end
    
    # Get param value in proper type.
    def value_to_type(value)
      if @options[:type] == :integer
        Integer(value)
      elsif @options[:type] == :float
        Float(value)
      else
        value
      end
    end

  end
end