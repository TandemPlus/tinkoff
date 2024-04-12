module Tinkoff
  class Request
    BASE_URL = 'https://securepay.tinkoff.ru/v2/'.freeze
    HEADER = { 'Content-Type' => 'application/json' }.freeze

    def initialize(path, params = {})
      @url = BASE_URL + path
      @params = params
    end

    def perform
      prepare_params
      response = HTTParty.post(@url, body: @params.to_json, headers: HEADER).parsed_response
      Tinkoff::Payment.new(response)
    end

    private

    def prepare_params
      # Add terminal key and password
      @params.merge!(default_params)
      # Sort params by key
      @params = @params.sort.to_h
      # Add token (signature)
      @params[:Token] = token
    end

    # В массив нужно добавить только параметры корневого объекта.
    # Вложенные объекты и массивы не участвуют в расчете токена.
    def token
      token_params = @params.except(:DATA, :Receipt).merge({ Password: Tinkoff.config.password })
      values = token_params.sort.to_h.values.join
      Digest::SHA256.hexdigest(values)
    end

    def default_params
      {
        TerminalKey: Tinkoff.config.terminal_key
      }
    end
  end
end
