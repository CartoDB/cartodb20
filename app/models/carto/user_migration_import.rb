# encoding: UTF-8

require 'active_record'
require 'fileutils'
require_relative '../../../services/user-mover/import_user'
require_dependency 'resque/user_migration_jobs'

module Carto
  class UserMigrationImport < ::ActiveRecord::Base
    belongs_to :organization, class_name: Carto::Organization
    belongs_to :user, class_name: Carto::User
    belongs_to :log, class_name: Carto::Log

    STATE_PENDING = 'pending'.freeze
    STATE_DOWNLOADING = 'downloading'.freeze
    STATE_IMPORTING = 'importing'.freeze
    STATE_COMPLETE = 'complete'.freeze
    STATE_FAILURE = 'failure'.freeze
    VALID_STATES = [STATE_PENDING, STATE_DOWNLOADING, STATE_IMPORTING, STATE_COMPLETE, STATE_FAILURE].freeze

    after_initialize :set_defaults

    validates :state, inclusion: { in: VALID_STATES }
    validates :database_host, presence: true
    validates :exported_file, presence: true
    validates :json_file, presence: true
    validate :valid_org_import

    def run_import
      assert_organization_does_not_exist
      log.append('=== Downloading ===')
      update_attributes(state: STATE_DOWNLOADING)
      package = UserMigrationPackage.for_import(id, log)
      package.download(exported_file)

      log.append('=== Importing ===')
      update_attributes(state: STATE_IMPORTING)

      service = (org_import? ? Carto::OrganizationMetadataExportService : Carto::UserMetadataExportService).new
      import(service, package)

      log.append('=== Complete ===')
      update_attributes(state: STATE_COMPLETE)
    rescue => e
      log.append_exception('Importing', exception: e)
      CartoDB::Logger.error(exception: e, message: 'Error importing user data', job: inspect)
      update_attributes(state: STATE_FAILURE)
      false
    ensure
      package.present? && package.cleanup
    end

    def enqueue
      Resque.enqueue(Resque::UserMigrationJobs::Import, import_id: id)
    end

    private

    def assert_organization_does_not_exist
      if organization.present? && Carto::Organization.where(id: organization.id).any?
        raise OrganizationAlreadyExists.new
      end
    end

    def valid_org_import
      if org_import?
        errors.add(:user_id, "user_id can't be present") if user_id.present?
      else
        errors.add(:organization_id, "organization_id can't be present") if organization_id.present?
      end
    end

    def import(service, package)
      @import_job = CartoDB::DataMover::ImportJob.new(import_job_arguments(package.data_dir))
      imported = do_import_metadata(package, service) if import_metadata?
      do_import_data(package, service)
      import_visualizations(imported, package, service) if import_metadata?
    end

    def import_visualizations(imported, package, service)
      log.append('=== Importing visualizations and search tweets ===')
      begin
        ActiveRecord::Base.transaction do
          service.import_metadata_from_directory(imported, package.meta_dir)
        end
      rescue => e
        log.append('=== Error importing visualizations and search tweets. Rollback! ===')
        rollback_import_data
        service.rollback_import_from_directory(package.meta_dir)
        raise e
      end
    end

    def do_import_data(package, service)
      log.append('=== Importing data ===')
      begin
        @import_job.run!
      rescue => e
        log.append('=== Error importing data. Rollback! ===')
        rollback_import_data
        service.rollback_import_from_directory(package.meta_dir) if import_metadata?
        raise e
      ensure
        @import_job.terminate_connections
      end
    end

    def rollback_import_data
      @import_job.add_options(rollback: true,
                              mode: :rollback,
                              drop_database: true,
                              drop_roles: true)
      @import_job.rollback!
    end

    def do_import_metadata(package, service)
      log.append('=== Importing metadata ===')
      begin
        imported = service.import_from_directory(package.meta_dir)
      rescue OrganizationAlreadyExists => e
        log.append('Organization already exists. Skipping!')
        raise e
      rescue => e
        log.append('=== Error importing metadata. Rollback! ===')
        service.rollback_import_from_directory(package.meta_dir)
        raise e
      end
      org_import? ? self.organization = imported : self.user = imported
      update_database_host
      save!
      imported
    end

    def update_database_host
      users.each do |user|
        Rollbar.info("Updating database conection for user #{user.username} to #{database_host}")
        user.database_host = database_host
        user.save!
        ::User[user.id].reload # This is because Sequel models are being cached along request. This forces reload.
        # It's being used in visualizations_export_persistence_service.rb#save_import
      end
    end

    def users
      org_import? ? organization.users : [user]
    end

    def import_only_data?
      # If the destination user/org already exists, import only data (same cloud, different DBs)
      org_import? ? organization.present? : user.present?
    end

    def import_job_arguments(data_dir)
      export_file = json_file.split('/').last

      {
        job_uuid: id,
        file: "#{data_dir}/#{export_file}",
        data: true,
        metadata: false,
        host: database_host,
        rollback: false,
        # This is used to import a non-org user into an organization. It is untested and unsupported.
        # Disabling it unconditionally until we need it makes sense.
        # into_org_name: org_import? || organization.nil? ? nil : organization.name,
        into_org_name: nil,
        mode: :import,
        logger: log.logger,
        import_job_logger: log.logger
      }
    end

    def set_defaults
      self.log = Carto::Log.create(type: 'user_migration_import') unless log
      self.state = STATE_PENDING unless state

      save
    end
  end
end
