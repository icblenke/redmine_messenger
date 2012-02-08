module RedmineMessenger
  module Messengers
    class MockMessenger < Messenger

      def initialize(config, logger)
        super(config)
	@logger = logger
      end
    
    end
  end
end
