class Client
  include ApiHelper

  MESSAGES = {
    start: Start,
    done: Done
  }.freeze

  CALLBACKS = {
    menu: Menu,
    create_group: CreateGroup,
    list_of_groups: ListOfGroups,
    pick_group: PickGroup,
    edit_group_name: EditGroupName,
    delete_group: DeleteGroup,
    add_files: AddFiles
  }.freeze

  REPLIES = {
    create_group_reply: CreateGroupReply,
    edit_group_name_reply: EditGroupNameReply
  }.freeze

  REPLY_TEXTS = {
    'Назовите группу': :create_group_reply,
    'Введите новое имя группы': :edit_group_name_reply
  }.freeze

  STATES = {
    normal: 0,
    sending_files: 1
  }.freeze

  def start
    Telegram::Bot::Client.run(ENV['TOKEN']) { |bot| listen_to_messages(bot) }
  end

  private

  def listen_to_messages(bot)
    bot.listen do |message|
      case message
      when Telegram::Bot::Types::Message
        if message.text && message.reply_to_message.nil?
          handle_message(bot, message)
        elsif message.reply_to_message
          handle_reply(bot, message)
        elsif message.document && REDIS.get('current-process') == STATES[:sending_files].to_s
          handle_files(bot, message)
        end
      when Telegram::Bot::Types::CallbackQuery
        handle_callback(bot, message)
      end
    end
  end

  def handle_message(bot, message)
    parser = Parser.new(message, type: :message)
    return send_message(bot, message, 'Нет такой команды') unless parser.command

    MESSAGES[parser.command].new(bot, message).call
  end

  def handle_callback(bot, message)
    parser = Parser.new(message, type: :callback)
    return send_message(bot, message, 'Нет такой команды') unless parser.command

    CALLBACKS[parser.command].new(bot, message).call
  end

  def handle_reply(bot, message)
    parser = Parser.new(message, type: :reply)
    return send_message(bot, message, 'Нет такой команды') unless parser.command

    REPLIES[parser.command].new(bot, message).call
  end

  def handle_files(bot, message)
    if message.document.is_a?(Array)
      message.document.each { |doc| STORAGE.write_to_files_table(doc.file_id, REDIS.hget('current-group', 'id')) }
    else
      STORAGE.write_to_files_table(message.document.file_id, REDIS.hget('current-group', 'id'))
    end
  end
end