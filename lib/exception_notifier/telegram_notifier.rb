require 'telegram/bot'

module ExceptionNotifier
  class TelegramNotifier < BaseNotifier
    include ExceptionNotifier::BacktraceCleaner

    attr_reader :channel_id
    attr_reader :bot

    def initialize(options)
      super
      begin
        bot_token   = options.delete(:bot_token)
        @channel_id = options.delete(:channel_id)
        @bot        = ::Telegram::Bot::Client.new(bot_token)
      rescue
        @bot = nil
      end
    end

    def call(exception, options = {})
      return unless bot

      message =
        if options[:accumulated_errors_count].to_i > 1
          "=== The exception occurred #{options[:accumulated_errors_count]} times: '#{exception.message}'"
        else
          "=== A new exception occurred: \n\n #{exception.message} \n\n"
        end

      message += "=== Backtrace: \n\n #{exception.backtrace.first}" if exception.backtrace
      send_notice(exception, options, message) do |msg, _|
        bot.api.send_message(chat_id: channel_id, text: msg)
      end
    end
  end
end
