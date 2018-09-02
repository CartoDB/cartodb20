<div class="u-inner Header-inner">
  <div class="Header-navigation">
    <ul class="Header-navigationList">
      <li class="js-logo"></li>
      <li>
        <ul class="Header-navigationBreadcrumb">
          <% if (organizationName) { %>
            <li class="Header-navigationBreadcrumbItem CDB-Text CDB-Size-large"><p class="Header-navigationBreadcrumbParagraph"><%= organizationName %></p> /</li>
          <% } %>
          <li class="Header-navigationBreadcrumbItem CDB-Text CDB-Size-large">
            <p class="Header-navigationBreadcrumbParagraph"><a href="<%= homeUrl %>" class="Header-navigationBreadcrumbLink"><%= nameOrUsername %></a></p> /
          </li>
          <li class="Header-navigationBreadcrumbItem js-breadcrumb-dropdown CDB-Text CDB-Size-large"></li>
        </ul>
      </li>
    </ul>
  </div>
  <div class="Header-settings">
    <ul class="Header-settingsList CDB-Text CDB-Size-medium">
      <% if (!isCartoDBHosted) { %>
        <li class="Header-settingsItem">
          <a target="_blank" href="<%- _t('guides_link') %>" class="CDB-Text is-semibold Header-settingsLink Header-settingsLink--dashboard"><%- _t('guides_name') %></a>
        </li>
        <li class="Header-settingsItem">
          <a target="_blank" href="<%- _t('dev_link') %>" class="CDB-Text is-semibold Header-settingsLink Header-settingsLink--dashboard"><%- _t('dev_name') %></a>
        </li>
      <% } %>
      <li class="Header-settingsItem Header-settingsItemNotifications js-user-notifications">
        <button class="UserNotifications">
          <i class="UserNotifications-Icon CDB-IconFont CDB-IconFont-Alert"></i>
        </button>
      </li>
      <li class="Header-settingsItem Header-settingsItem--avatar">
        <button class="UserAvatar js-settings-dropdown">
          <img src="<%= avatar %>" class="UserAvatar-img UserAvatar-img--medium">
        </button>
      </li>
    </ul>
  </div>
</div>
