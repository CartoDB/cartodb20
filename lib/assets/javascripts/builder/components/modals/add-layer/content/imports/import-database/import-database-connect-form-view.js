const CartoNode = require('carto-node');
const checkAndBuildOpts = require('builder/helpers/required-opts');
const CoreView = require('backbone/core-view');
const template = require('./import-database-connect-form.tpl');
const sidebarTemplate = require('./import-database-sidebar.tpl');

const REQUIRED_OPTS = [
  'configModel',
  'model',
  'service'
];

module.exports = CoreView.extend({

  events: {
    'keyup .js-textInput': '_onTextChanged',
    'submit .js-form': '_onSubmitForm'
  },

  initialize: function (opts) {
    checkAndBuildOpts(opts, REQUIRED_OPTS, this);

    this._initBinds();
  },

  render: function () {
    this.$el.html(template(this.options));
    this._addSidebar();

    this.form = {
      submit: this.$('.js-submit'),
      server: this.$('.js-server'),
      port: this.$('.js-port'),
      database: this.$('.js-database'),
      username: this.$('.js-username'),
      password: this.$('.js-password')
    };

    return this;
  },

  _addSidebar: function () {
    this.$el.find('.ImportPanel-sidebar').append(
      sidebarTemplate(this.options)
    );
  },

  _initBinds: function () {
    this._model.bind('change:state', this._checkVisibility, this);
  },

  _checkVisibility: function () {
    const state = this._model.get('state');
    if (state === 'idle' || state === 'error') {
      this.show();
    } else {
      this.hide();
    }
  },

  _onTextChanged: function () {
    (this._isFormFilled() ? this._enableSubmit() : this._disableSubmit());
  },

  _disableSubmit: function () {
    this.form.submit.attr('disabled', 'disabled');
    this.form.submit.addClass('is-disabled');
  },

  _enableSubmit: function () {
    this.form.submit.removeAttr('disabled');
    this.form.submit.removeClass('is-disabled');
  },

  _isFormFilled: function () {
    return this.form.server.val() !== '' &&
           this.form.port.val() !== '' &&
           this.form.database.val() !== '' &&
           this.form.username.val() !== '' &&
           this.form.password.val() !== '';
  },

  _onSubmitForm: function (e) {
    if (e) this.killEvent(e);

    this._model.connector = this._getFormParams();

    if (this._model.connector) {
      this._checkConnection(this._model.connector);
    }
  },

  _getFormParams: function () {
    return {
      server: this.form.server.val(),
      port: this.form.port.val(),
      database: this.form.database.val(),
      username: this.form.username.val(),
      password: this.form.password.val()
    };
  },

  _checkConnection: function (params) {
    const client = new CartoNode.AuthenticatedClient();
    const onSuccess = this._checkConnectionSuccess.bind(this);

    try {
      client.checkDBConnectorsConnection(this._service, params, (errors, response, data) => {
        onSuccess(data);
      });
    } catch (error) {
      this._checkConnectionError();
    }
  },

  _checkConnectionSuccess: function (data) {
    if (data && data.connected) {
      this._model.set('state', 'connected');
      this._model.set('service_name', 'connector');
    } else {
      this._model.set('state', 'error');
    }
  },

  _checkConnectionError: function () {
    this._model.set('state', 'error');
  }
});