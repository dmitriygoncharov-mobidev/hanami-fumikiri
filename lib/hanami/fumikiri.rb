require 'hanami/controller'

module Hanami
  module Fumikiri

    def self.included(base)
      base.class_eval do
        expose :current_user
      end
    end

    private
    def current_user
      validate_jwt
      @current_user = UserRepository.find(user_id)
      raise MissingUserError unless @current_user # or redirect_to '/some_url'
      @current_user
    end

    def authenticate!
      redirect_to '/login' unless authenticated?
    end

    def authenticated?
      !!current_user
    end

    def user_session
      nil # temporary until real session
    end

    def user_id
      user_session || token_sub
    end

    def token_sub
      @decoded_token.fetch('sub') { raise MissingSubError }
    end

    def user_token
      request.env.fetch('Authentication') { raise MissingTokenError }
    end

    def validate_jwt
      begin
        token = user_token.sub(/Bearer\s/, '')
        @decoded_token = JWT.decode(token, ENV['JWT_SECRET'])
        # make better errors
        # we should let this error bubble-up
        # raise InvalidTokenError if @decoded_token['sub'].empty?

      rescue JWT::DecodeError
        # make better errors
        raise InvalidTokenError
      end
    end
  end
end

::Hanami::Controller.configure do
  prepare do
    include Hanami::Fumikiri
    before :authenticate!
  end
end
