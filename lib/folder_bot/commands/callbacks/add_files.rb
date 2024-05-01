module FolderBot
  module Commands
    module Callbacks
      class AddFiles < Command
        def call
          delete_message(@bot, read(:current_message))
          send_message(@bot, @message, 'Отправляйте файлы. Закончили? Вызывайте /done')
          save :current_context, '/add_files_reply'
        end
      end
    end
  end
end
