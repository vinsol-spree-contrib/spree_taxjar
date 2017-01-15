module TaxjarHelper
  class Pretty < Logger::Formatter
    # Provide a call() method that returns the formatted message.
    def call(severity, time, program_name, message)
      "#{time.utc.iso8601} #{Process.pid} TID-#{Thread.current.object_id.to_s(36)}#{context} #{severity}: #{message}\n"
    end

    def context
      Thread.current[:spree_taxjar_context] ? " #{c}" : ''
    end
  end

  class TaxjarLog
    def initialize(path_name, file_name, log_info = nil, schedule = nil)
      schedule = "weekly" unless schedule != nil
      @logger ||= Logger.new("#{Rails.root}/log/#{path_name}.log", schedule)
      @logger.formatter = Pretty.new
      progname(file_name.split("/").last.chomp(".rb"))
      info(log_info) unless log_info.nil?
    end

    def logger
      @logger
    end

    def logger_enabled?
      true
    end

    def progname(progname = nil)
      progname.nil? ? logger.progname : logger.progname = progname
    end

    def info(log_info = nil)
      if logger_enabled?
        logger.info log_info unless log_info.nil?
      end
    end

    def info_and_debug(log_info, response)
      if logger_enabled?
        logger.info log_info
        if response.is_a?(Hash)
          logger.debug JSON.generate(response)
        else
          logger.debug response
        end
      end
    end

    def debug(error, text = nil)
      if logger_enabled?
        logger.debug error
        if text.nil?
          error
        else
          logger.debug text
          text
        end
      end
    end
  end
end
