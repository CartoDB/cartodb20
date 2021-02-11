require_relative '../connection_adapter'

module Carto
  class ConnectionAdapter
    # Connection adapter for BigQuery:
    # * Manages BigQuery connector specifics (parameter validation & confidentiality, singletonness)
    # * Saves credentials in redis
    # * Manages Spatial Extension Setup
    class BigQuery < ConnectionAdapter

      BQ_CONFIDENTIAL_PARAMS = %w(service_account refresh_token access_token).freeze
      NON_CONNECTOR_PARAMETERS = [].freeze
      BQ_ADVANCED_CENTRAL_ATTRIBUTE = :bq_advanced
      BQ_ADVANCED_PROJECT_CENTRAL_ATTRIBUTE = :bq_advanced_project

      def initialize(connection)
        super(connection, confidential_parameters: BQ_CONFIDENTIAL_PARAMS)
      end

      def filtered_connection_parameters
        @connection.parameters&.except(*NON_CONNECTOR_PARAMETERS)
      end

      def singleton?
        true
      end

      def errors
        errors = super
        if @connection.connection_type == Carto::Connection::TYPE_DB_CONNECTOR
          if @connection.parameters['refresh_token'].present?
            errors << 'Parameter refresh_token not supported for db-connection; use OAuth connection instead'
          end
          if @connection.parameters['access_token'].present?
            errors << 'Parameter access_token not supported through connections; use import API'
          end
        end
        errors
      end

      def create
        super
        update_redis_metadata
        create_spatial_extension_setup
      end

      def destroy
        super
        remove_redis_metadata
        remove_spatial_extension_setup
      end

      def update
        super
        update_redis_metadata
        update_spatial_extension_setup
      end

      # If necessary this is how to check if the spatial extension has been successfully activated:
      # def bq_advanced?
      #   central_user_data = Cartodb::Central.new.get_user(@user.username)
      #   central_user_data[BQ_ADVANCED_CENTRAL_ATTRIBUTE.to_s]
      # end

      private

      def central
        @central ||= Cartodb::Central.new
      end

      def create_spatial_extension_setup
        central.update_user(
          @connection.user.username,
          BQ_ADVANCED_CENTRAL_ATTRIBUTE => true,
          BQ_ADVANCED_PROJECT_CENTRAL_ATTRIBUTE => @connection.parameters['billing_project']
        )
      end

      def remove_spatial_extension_setup
        central.update_user(
          @connection.user.username,
          BQ_ADVANCED_CENTRAL_ATTRIBUTE => false,
          BQ_ADVANCED_PROJECT_CENTRAL_ATTRIBUTE => nil
        )
      end

      def update_spatial_extension_setup
        if @connection.changes[:parameters]
          old_parameters, new_parameters = @connection.changes[:parameters]
          if old_parameters['billing_project'] != new_parameters['billing_project']
            central.update_user(
              @connection.user.username,
              BQ_ADVANCED_CENTRAL_ATTRIBUTE => true,
              BQ_ADVANCED_PROJECT_CENTRAL_ATTRIBUTE => new_parameters['billing_project']
            )
          end
        end
      end

      def update_redis_metadata
        if @connection.parameters['service_account'].present?
          $users_metadata.hmset(
            bigquery_redis_key,
            'service_account', @connection.parameters['service_account'],
            'billing_project', @connection.parameters['billing_project']
          )
        end
      end

      def remove_redis_metadata
        $users_metadata.del bigquery_redis_key
      end

      def bigquery_redis_key
        "google:bq_settings:#{@connection.user.username}"
      end

    end
  end
end