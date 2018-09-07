<div class="u-flex u-justifyCenter">
  <div class="Modal-inner Modal-inner--grid u-flex u-justifyCenter">
    <div class="Modal-icon">
      <svg width="24px" height="25px" viewbox="521 436 24 25" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        <path d="M524.5,440 L540.5,440 L540.5,460 L524.5,460 L524.5,440 Z M528.5,437 L536.5,437 L536.5,440 L528.5,440 L528.5,437 Z M522,440 L544,440 L522,440 Z M528.5,443.5 L528.5,455.5 L528.5,443.5 Z M532.5,443.5 L532.5,455.5 L532.5,443.5 Z M536.5,443.5 L536.5,455.5 L536.5,443.5 Z" id="Shape" stroke="#F19243" stroke-width="1" fill="none"/>
      </svg>
    </div>
    <div>
      <form accept-charset="UTF-8" action="<%- formAction %>" method="post">
        <input name="utf8" type="hidden" value="&#x2713;" />
        <input name="authenticity_token" type="hidden" value="<%- authenticityToken %>" />
        <input name="_method" type="hidden" value="delete" />

        <h2 class=" CDB-Text CDB-Size-huge is-light u-bSpace--xl"><%= _t('dashboard.views.organization.org_notif.about_remove') %></h2>
        <p class="CDB-Text CDB-Size-large u-altTextColor"><%= _t('dashboard.views.organization.org_notif.sure') %></p>

        <ul class="Modal-listActions u-flex u-alignCenter">
          <li class="Modal-listActionsitem">
            <button class="CDB-Button CDB-Button--secondary CDB-Button--big js-cancel">
              <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-medium u-upperCase"><%= _t('dashboard.views.organization.org_notif.cancel') %></span>
            </button>
          </li>
          <li class="Modal-listActionsitem">
            <button class="CDB-Button CDB-Button--primary CDB-Button--big js-submit">
              <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-medium u-upperCase"><%= _t('dashboard.views.organization.org_notif.ok') %></span>
            </button>
          </li>
        </ul>
      </form>
    </div>
  </div>
</div>
