#require 'ostruct'
require_relative '../spec_helper'
#require_relative 'user_shared_examples'
#require_relative '../../services/dataservices-metrics/lib/isolines_usage_metrics'
#require_relative '../../services/dataservices-metrics/lib/observatory_snapshot_usage_metrics'
#require_relative '../../services/dataservices-metrics/lib/observatory_general_usage_metrics'
#require 'factories/organizations_contexts'
#require_relative '../../app/model_factories/layer_factory'
#require_dependency 'cartodb/redis_vizjson_cache'
#require 'helpers/rate_limits_helper'
#require 'helpers/unique_names_helper'
#require 'helpers/account_types_helper'
#require 'factories/users_helper'
#require 'factories/database_configuration_contexts'


describe User do
  #include UniqueNamesHelper
  #include AccountTypesHelper
  #include RateLimitsHelper

  before(:each) do
    CartoDB::UserModule::DBService.any_instance.stubs(:enable_remote_db_user).returns(true)
  end

  before(:all) do
    bypass_named_maps

    @user_password = 'admin123'
    puts "\n[rspec][user_spec] Creating test user databases..."
    @user     = create_user :email => 'admin@example.com', :username => 'admin', :password => @user_password
    @user2    = create_user :email => 'user@example.com',  :username => 'user',  :password => 'user123'

    puts "[rspec][user_spec] Loading user data..."
    reload_user_data(@user) && @user.reload

    puts "[rspec][user_spec] Running..."
  end

  before(:each) do
    bypass_named_maps
    CartoDB::Varnish.any_instance.stubs(:send_command).returns(true)
    CartoDB::UserModule::DBService.any_instance.stubs(:enable_remote_db_user).returns(true)
    Table.any_instance.stubs(:update_cdb_tablemetadata)
  end

  after(:all) do
    bypass_named_maps
    @user.destroy
    @user2.destroy
    @account_type.destroy if @account_type
    @account_type_org.destroy if @account_type_org
  end

  it "should have a default dashboard_viewed? false" do
    user = ::User.new
    user.dashboard_viewed?.should be_false
  end

  it "should reset dashboard_viewed when dashboard gets viewed" do
    user = ::User.new
    user.view_dashboard
    user.dashboard_viewed?.should be_true
  end

  describe "avatar checks" do
    let(:user1) do
      create_user(email: 'ewdewfref34r43r43d32f45g5@example.com', username: 'u1', password: 'foobar')
    end

    after(:each) do
      user1.destroy
    end

    it "should load a cartodb avatar url if no gravatar associated" do
      avatar_kind = Cartodb.config[:avatars]['kinds'][0]
      avatar_color = Cartodb.config[:avatars]['colors'][0]
      avatar_base_url = Cartodb.config[:avatars]['base_url']
      Random.any_instance.stubs(:rand).returns(0)
      gravatar_url = %r{gravatar.com}
      Typhoeus.stub(gravatar_url, { method: :get }).and_return(Typhoeus::Response.new(code: 404))
      user1.stubs(:gravatar_enabled?).returns(true)
      user1.avatar_url = nil
      user1.save
      user1.reload_avatar
      user1.avatar_url.should == "#{avatar_base_url}/avatar_#{avatar_kind}_#{avatar_color}.png"
    end

    it "should load a cartodb avatar url if gravatar disabled" do
      avatar_kind = Cartodb.config[:avatars]['kinds'][0]
      avatar_color = Cartodb.config[:avatars]['colors'][0]
      avatar_base_url = Cartodb.config[:avatars]['base_url']
      Random.any_instance.stubs(:rand).returns(0)
      gravatar_url = %r{gravatar.com}
      Typhoeus.stub(gravatar_url, { method: :get }).and_return(Typhoeus::Response.new(code: 200))
      user1.stubs(:gravatar_enabled?).returns(false)
      user1.avatar_url = nil
      user1.save
      user1.reload_avatar
      user1.avatar_url.should == "#{avatar_base_url}/avatar_#{avatar_kind}_#{avatar_color}.png"
    end

    it "should load a the user gravatar url" do
      gravatar_url = %r{gravatar.com}
      Typhoeus.stub(gravatar_url, { method: :get }).and_return(Typhoeus::Response.new(code: 200))
      user1.stubs(:gravatar_enabled?).returns(true)
      user1.reload_avatar
      user1.avatar_url.should == "//#{user1.gravatar_user_url}"
    end

    describe '#gravatar_enabled?' do
      it 'should be enabled by default (every setting but false will enable it)' do
        user = ::User.new
        Cartodb.with_config(avatars: {}) { user.gravatar_enabled?.should be_true }
        Cartodb.with_config(avatars: { 'gravatar_enabled' => true }) { user.gravatar_enabled?.should be_true }
        Cartodb.with_config(avatars: { 'gravatar_enabled' => 'true' }) { user.gravatar_enabled?.should be_true }
        Cartodb.with_config(avatars: { 'gravatar_enabled' => 'wadus' }) { user.gravatar_enabled?.should be_true }
      end

      it 'can be disabled' do
        user = ::User.new
        Cartodb.with_config(avatars: { 'gravatar_enabled' => false }) { user.gravatar_enabled?.should be_false }
        Cartodb.with_config(avatars: { 'gravatar_enabled' => 'false' }) { user.gravatar_enabled?.should be_false }
      end
    end
  end

  describe '#private_maps_enabled?' do
    it 'should not have private maps enabled by default' do
      user_missing_private_maps = create_user email: 'user_mpm@example.com',
                                              username: 'usermpm',
                                              password: '000usermpm'
      user_missing_private_maps.private_maps_enabled?.should eq false
      user_missing_private_maps.destroy
    end

    it 'should have private maps if enabled' do
      user_with_private_maps = create_user email: 'user_wpm@example.com',
                                           username: 'userwpm',
                                           password: '000userwpm',
                                           private_maps_enabled: true
      user_with_private_maps.private_maps_enabled?.should eq true
      user_with_private_maps.destroy
    end

    it 'should not have private maps if disabled' do
      user_without_private_maps = create_user email: 'user_opm@example.com',
                                              username: 'useropm',
                                              password: '000useropm',
                                              private_maps_enabled: false
      user_without_private_maps.private_maps_enabled?.should eq false
      user_without_private_maps.destroy
    end
  end

  describe "#purge_redis_vizjson_cache" do
    it "shall iterate on the user's visualizations and purge their redis cache" do
      # Create a few tables with their default vizs
      (1..3).each do |i|
        t = Table.new
        t.user_id = @user.id
        t.save
      end

      collection = CartoDB::Visualization::Collection.new.fetch({user_id: @user.id})
      redis_spy = RedisDoubles::RedisSpy.new
      redis_vizjson_cache = CartoDB::Visualization::RedisVizjsonCache.new()
      redis_embed_cache = EmbedRedisCache.new()
      CartoDB::Visualization::RedisVizjsonCache.any_instance.stubs(:redis).returns(redis_spy)
      EmbedRedisCache.any_instance.stubs(:redis).returns(redis_spy)


      redis_vizjson_keys = collection.map { |v|
        [
          redis_vizjson_cache.key(v.id, false), redis_vizjson_cache.key(v.id, true),
          redis_vizjson_cache.key(v.id, false, 3), redis_vizjson_cache.key(v.id, true, 3),
          redis_vizjson_cache.key(v.id, false, '3n'), redis_vizjson_cache.key(v.id, true, '3n'),
          redis_vizjson_cache.key(v.id, false, '3a'), redis_vizjson_cache.key(v.id, true, '3a'),
        ]
      }.flatten
      redis_vizjson_keys.should_not be_empty

      redis_embed_keys = collection.map { |v|
        [redis_embed_cache.key(v.id, false), redis_embed_cache.key(v.id, true)]
      }.flatten
      redis_embed_keys.should_not be_empty

      @user.purge_redis_vizjson_cache

      redis_spy.deleted.should include(*redis_vizjson_keys)
      redis_spy.deleted.should include(*redis_embed_keys)
      redis_spy.deleted.count.should eq redis_vizjson_keys.count + redis_embed_keys.count
      redis_spy.invokes(:del).count.should eq 2
      redis_spy.invokes(:del).map(&:sort).should include(redis_vizjson_keys.sort)
      redis_spy.invokes(:del).map(&:sort).should include(redis_embed_keys.sort)
    end

    it "shall not fail if the user does not have visualizations" do
      user = create_user
      collection = CartoDB::Visualization::Collection.new.fetch({user_id: user.id})
      # 'http' keys
      redis_keys = collection.map(&:redis_vizjson_key)
      redis_keys.should be_empty
      # 'https' keys
      redis_keys = collection.map { |item| item.redis_vizjson_key(true) }
      redis_keys.should be_empty

      CartoDB::Visualization::Member.expects(:redis_cache).never

      user.purge_redis_vizjson_cache

      user.destroy
    end
  end

  describe '#visualization_count' do
    include_context 'organization with users helper'
    include TableSharing

    it 'filters by type if asked' do
      vis = FactoryGirl.create(:carto_visualization, user_id: @org_user_1.id, type: Carto::Visualization::TYPE_DERIVED)

      @org_user_1.visualization_count.should eq 1
      @org_user_1.visualization_count(type: Carto::Visualization::TYPE_DERIVED).should eq 1
      [Carto::Visualization::TYPE_CANONICAL, Carto::Visualization::TYPE_REMOTE].each do |type|
        @org_user_1.visualization_count(type: type).should eq 0
      end

      vis.destroy
    end

    it 'filters by privacy if asked' do
      vis = FactoryGirl.create(:carto_visualization,
                               user_id: @org_user_1.id,
                               privacy: Carto::Visualization::PRIVACY_PUBLIC)

      @org_user_1.visualization_count.should eq 1
      @org_user_1.visualization_count(privacy: Carto::Visualization::PRIVACY_PUBLIC).should eq 1
      [
        Carto::Visualization::PRIVACY_PRIVATE,
        Carto::Visualization::PRIVACY_LINK,
        Carto::Visualization::PRIVACY_PROTECTED
      ].each do |privacy|
        @org_user_1.visualization_count(privacy: privacy).should eq 0
      end

      vis.destroy
    end

    it 'filters by shared exclusion if asked' do
      vis = FactoryGirl.create(:carto_visualization, user_id: @org_user_1.id, type: Carto::Visualization::TYPE_DERIVED)
      share_visualization_with_user(vis, @org_user_2)

      @org_user_2.visualization_count.should eq 1
      @org_user_2.visualization_count(exclude_shared: true).should eq 0

      vis.destroy
    end

    it 'filters by raster exclusion if asked' do
      vis = FactoryGirl.create(:carto_visualization, user_id: @org_user_1.id, kind: Carto::Visualization::KIND_RASTER)

      @org_user_1.visualization_count.should eq 1
      @org_user_1.visualization_count(exclude_raster: true).should eq 0

      vis.destroy
    end
  end

  describe 'viewer user' do
    def verify_viewer_quota(user)
      user.quota_in_bytes.should eq 0
      user.geocoding_quota.should eq 0
      user.soft_geocoding_limit.should eq false
      user.twitter_datasource_quota.should eq 0
      user.soft_twitter_datasource_limit.should eq false
      user.here_isolines_quota.should eq 0
      user.soft_here_isolines_limit.should eq false
      user.obs_snapshot_quota.should eq 0
      user.soft_obs_snapshot_limit.should eq false
      user.obs_general_quota.should eq 0
      user.soft_obs_general_limit.should eq false
    end

    describe 'creation' do
      it 'assigns 0 as quota and no soft limit no matter what is requested' do
        @user = create_user email: 'u_v@whatever.com', username: 'viewer', password: 'user11', viewer: true,
                            geocoding_quota: 10, soft_geocoding_limit: true, twitter_datasource_quota: 100,
                            soft_twitter_datasource_limit: 10, here_isolines_quota: 10, soft_here_isolines_limit: true,
                            obs_snapshot_quota: 100, soft_obs_snapshot_limit: true, obs_general_quota: 100,
                            soft_obs_general_limit: true
        verify_viewer_quota(@user)
        @user.destroy
      end
    end

    describe 'builder -> viewer' do
      it 'assigns 0 as quota and no soft limit no matter what is requested' do
        @user = create_user email: 'u_v@whatever.com', username: 'builder-to-viewer', password: 'user11', viewer: false,
                            geocoding_quota: 10, soft_geocoding_limit: true, twitter_datasource_quota: 100,
                            soft_twitter_datasource_limit: 10, here_isolines_quota: 10, soft_here_isolines_limit: true,
                            obs_snapshot_quota: 100, soft_obs_snapshot_limit: true, obs_general_quota: 100,
                            soft_obs_general_limit: true
        # Random check, but we can trust create_user
        @user.quota_in_bytes.should_not eq 0

        @user.viewer = true
        @user.save
        @user.reload
        verify_viewer_quota(@user)
        @user.destroy
      end
    end

    describe 'quotas' do
      it "can't change for viewer users" do
        @user = create_user(viewer: true)
        verify_viewer_quota(@user)
        @user.quota_in_bytes = 666
        @user.save
        @user.reload
        verify_viewer_quota(@user)
        @user.destroy
      end
    end
  end


  protected

  def create_org(org_name, org_quota, org_seats)
    organization = Organization.new
    organization.name = unique_name(org_name)
    organization.quota_in_bytes = org_quota
    organization.seats = org_seats
    organization.save
    organization
  end

  def tables_including_shared(user)
    Carto::VisualizationQueryBuilder
      .new
      .with_owned_by_or_shared_with_user_id(user.id)
      .with_type(Carto::Visualization::TYPE_CANONICAL)
      .build.map(&:table)
  end
end