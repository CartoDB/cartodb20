require 'spec_helper'

describe CentralUserCommands do
  let(:notifications_topic) { mock }
  let(:logger) { Carto::Common::Logger.new(nil) }
  let(:central_user_commands) do
    described_class.new(notifications_topic: notifications_topic,
                        logger: logger)
  end

  describe '#update_user' do
    let(:original_user) { create(:user) }
    let(:user) { original_user.reload } # Small trick to avoid reload in expectations
    let(:some_feature_flag) { create(:feature_flag, restricted: true) }

    it 'sets the required fields to their values' do
      user_params = { remote_user_id: original_user.id,
                      quota_in_bytes: 42 }
      message = Carto::Common::MessageBroker::Message.new(payload: user_params)
      central_user_commands.update_user(message)
      expect(user.quota_in_bytes).to eq 42
    end

    it 'adds feature flags when they are in the payload' do
      user_params = { remote_user_id: original_user.id,
                      feature_flags: [some_feature_flag.id] }
      message = Carto::Common::MessageBroker::Message.new(payload: user_params)
      central_user_commands.update_user(message)
      expect(user.has_feature_flag?(some_feature_flag.name)).to eq true
    end

    it 'removes feature flags when requested' do
      original_user.feature_flags << some_feature_flag
      user_params = { remote_user_id: original_user.id,
                      feature_flags: [] }
      message = Carto::Common::MessageBroker::Message.new(payload: user_params)
      central_user_commands.update_user(message)
      expect(user.has_feature_flag?(some_feature_flag.name)).to eq false
    end
  end

  describe '#create_user' do
    let(:account_type) { create_account_type_fg(nil) }
    let(:username) { Faker::Internet.username(separators: ['-']) }
    let(:default_user_params) do
      {
        username: username,
        email: Faker::Internet.safe_email,
        password: 'supersecret',
        account_type: account_type.account_type
      }
    end
    let(:message) { Carto::Common::MessageBroker::Message.new(payload: user_params) }
    let(:created_user) { Carto::User.find_by(username: username) }

    before { notifications_topic.stubs(:publish) }

    context 'when everything is OK' do
      let(:user_params) { default_user_params }

      it 'creates a user with the provided params' do
        central_user_commands.create_user(message)

        expect(created_user).to be_present
        expect(created_user.crypted_password).to be_present
      end
    end

    context 'when the payload contains invalid attributes' do
      let(:user_params) { default_user_params.merge(email: nil) }

      it 'raises an error' do
        expect { central_user_commands.create_user(message) }.to raise_error(Sequel::ValidationFailed)
      end
    end

    context 'when specifying custom rate limit attributes' do
      let(:rate_limits) { create(:rate_limits) }
      let(:user_params) do
        default_user_params.merge(rate_limit: rate_limits.api_attributes)
      end

      it 'assigns the correct rate limits' do
        central_user_commands.create_user(message)

        expect(created_user).to be_present
        expect(created_user.rate_limit.api_attributes).to eq(rate_limits.api_attributes)
      end
    end

    context 'with default account settings' do
      let(:upgraded_at_timestamp) { Time.zone.now }
      let(:user_params) do
        default_user_params.merge(
          private_tables_enabled: false,
          sync_tables_enabled: false,
          map_views_quota: 80,
          upgraded_at: upgraded_at_timestamp
        )
      end

      it 'creates the user with default account settings' do
        central_user_commands.create_user(message)

        expect(created_user).to be_present
        expect(created_user.quota_in_bytes).to eq(104_857_600)
        expect(created_user.table_quota).to eq(5)
        expect(created_user.public_map_quota).to be_nil
        expect(created_user.public_dataset_quota).to be_nil
        expect(created_user.private_map_quota).to be_nil
        expect(created_user.regular_api_key_quota).to be_nil
        expect(created_user.account_type).to eq('FREE')
        expect(created_user.private_tables_enabled).to eq(false)
        expect(created_user.upgraded_at).to be_present
      end
    end

    context 'with custom account settings' do
      let(:account_type) { create(:account_type, account_type: Faker::String.random(length: 8)) }
      let(:user_params) do
        default_user_params.merge(
          quota_in_bytes: 2_000,
          table_quota: 20,
          public_map_quota: 20,
          public_dataset_quota: 20,
          private_map_quota: 20,
          regular_api_key_quota: 20,
          account_type: account_type.account_type,
          private_tables_enabled: true,
          sync_tables_enabled: true,
          map_view_block_price: 15,
          geocoding_quota: 15,
          geocoding_block_price: 2,
          here_isolines_quota: 100,
          here_isolines_block_price: 5,
          obs_snapshot_quota: 100,
          obs_snapshot_block_price: 5,
          obs_general_quota: 100,
          obs_general_block_price: 5,
          notification: 'Test'
        )
      end

      it 'creates the user with custom account settings' do
        central_user_commands.create_user(message)

        expect(created_user).to be_present
        expect(created_user.quota_in_bytes).to eq(2_000)
        expect(created_user.table_quota).to eq(20)
        expect(created_user.public_map_quota).to eq(20)
        expect(created_user.public_dataset_quota).to eq(20)
        expect(created_user.private_map_quota).to eq(20)
        expect(created_user.regular_api_key_quota).to eq(20)
        expect(created_user.account_type).to eq(account_type.account_type)
        expect(created_user.private_tables_enabled).to eq(true)
        expect(created_user.sync_tables_enabled).to eq(true)
        expect(created_user.map_view_block_price).to eq(15)
        expect(created_user.geocoding_quota).to eq(15)
        expect(created_user.geocoding_block_price).to eq(2)
        expect(created_user.here_isolines_quota).to eq(100)
        expect(created_user.here_isolines_block_price).to eq(5)
        expect(created_user.obs_snapshot_quota).to eq(100)
        expect(created_user.obs_snapshot_block_price).to eq(5)
        expect(created_user.obs_general_quota).to eq(100)
        expect(created_user.obs_general_block_price).to eq(5)
        expect(created_user.notification).to eq('Test')
      end
    end
  end

  describe '#delete_user' do
    let(:user) { create(:user) }

    it 'deletes the inteded user' do
      user_params = { id: user.id }
      notifications_topic.expects(:publish).once.with(
        :user_deleted,
        { username: user.username }
      )
      message = Carto::Common::MessageBroker::Message.new(payload: user_params)
      central_user_commands.delete_user(message)
      expect(Carto::User.exists?(id: user.id)).to eq false
    end
  end
end
