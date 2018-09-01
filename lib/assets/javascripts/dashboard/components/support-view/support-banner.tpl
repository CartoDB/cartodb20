<div class="u-inner">
  <div class="SupportBanner-inner">
    <div class="SupportBanner-info">
      <h4 class="CDB-Text CDB-Size-large u-secondaryTextColor u-bSpace">
        <% if (userType === 'org_admin' || userType === 'client') { %>
          <%- _t('dashboard.components.support_view.support_banner.dedicated_support') %>
        <% } else if (isViewer) { %>
          <%- _t('dashboard.components.support_view.support_banner.become_builder', {orgDisplayEmail: orgDisplayEmail}) %>
        <% } else if (userType === 'org') { %>
          <%- _t('dashboard.components.support_view.support_banner.contact_org_admin', {orgDisplayEmail: orgDisplayEmail}) %>
        <% } else if (userType === "internal") { %>
          <% _t('dashboard.components.support_view.support_banner.outstanding') %>
        <% } else { %>
          <%- _t('dashboard.components.support_view.support_banner.contact_community') %>
        <% } %>
      </h4>
      <p class="CDB-Text CDB-Size-medium u-altTextColor">
        <% if (isViewer) { %>
          <%= _t('dashboard.components.support_view.support_banner.create_maps') %>
        <% } else if (userType === 'org' || userType === 'org_admin' || userType === 'client') { %>
          <%= _t('dashboard.components.support_view.support_banner.info_on_community') %>
        <% } else if (userType === "internal") { %>
          <%= _t('dashboard.components.support_view.support_banner.internal') %>
        <% } else { %>
          <%= _t('dashboard.components.support_view.support_banner.problem') %>
        <% } %>
      </p>
    </div>
    <% if (userType === 'org_admin') { %>
      <a href="mailto:<%- _t('email_enterprise') %>" class="SupportBanner-link CDB-Button CDB-Button--secondary">
        <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-medium u-upperCase"><%- _t('dashboard.components.support_view.support_banner.contact_support') %></span>
      </a>
    <% } else if (userType === 'org') { %>
        <a href="mailto:<%- orgDisplayEmail %>" class="SupportBanner-link CDB-Button CDB-Button--secondary">
          <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-medium u-upperCase"><%- _t('dashboard.components.support_view.support_banner.contact_admin') %></span>
        </a>
    <% } else if (userType === 'client' || userType === 'internal') { %>
      <a href="mailto:<%- _t('email_support') %>" class="SupportBanner-link CDB-Button CDB-Button--secondary">
        <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-medium u-upperCase"><%- _t('dashboard.components.support_view.support_banner.contact_us') %></span>
      </a>
    <% } else { %>
      <a href="<%- _t('community_link') %>" class="SupportBanner-link CDB-Button CDB-Button--secondary" target="_blank">
        <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-medium u-upperCase"><%- _t('dashboard.components.support_view.support_banner.community') %></span>
      </a>
    <% } %>
  </div>
</div>
