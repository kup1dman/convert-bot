module FolderBot
  class Client
    include Helpers::ApiHelper
    include Parser

    def initialize
      @session = Session.new(store: FolderBot::REDIS)
    end

    def start
      Telegram::Bot::Client.run(ENV['TOKEN']) do |bot|
        Signal.trap('INT') { bot.stop }
        listen_to_messages(bot)
      end
    end

    private

    def listen_to_messages(bot)
      bot.listen do |message|
        @session.build_session(user_id: message.from.id)

        case message
        when Telegram::Bot::Types::Message
          handle_data(bot, message, data: message.text, type: :messages) if message.text && message.reply_to_message.nil?
          handle_data(bot, message, data: @session[:current_context], type: :replies) if message.reply_to_message || message.document
        when Telegram::Bot::Types::CallbackQuery
          handle_data(bot, message, data: message.data, type: :callbacks)
        end
      end
    end

    def handle_data(bot, message, data:, type:)
      command(data, type)&.new(bot, message, @session)&.call || send_message(bot, message, 'Нет такой команды')
    end
  end
end
