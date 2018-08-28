<div class="IntermediateInfo">
  <div class="LayoutIcon <% isSearching ? 'LayoutIcon--negative' : '' %>">
    <i class="CDB-IconFont
      <% if (shared === "only") { %> CDB-IconFont-defaultUser
      <% } else if (liked) { %> CDB-IconFont-heartEmpty
      <% } else if (locked) { %> CDB-IconFont-lock
      <% } else { %> CDB-IconFont-lens <% } %>" />
  </div>
  <h4 class="CDB-Text CDB-Size-large u-mainTextColor u-secondaryTextColor u-bSpace--m u-tSpace-xl">
    <% if (page > 1 && totalItems === 0 && totalEntries > 0) { %>
      <%= _t('dashboard.views.dashboard.content_controller.templates.content_no_results.no_results') %>
    <% } %>

    <% if (liked && totalEntries === 0 ) { %>
      <%= _t('dashboard.views.dashboard.content_controller.templates.content_no_results.no_liked', {type: type}) %>
    <% } %>

    <% if (isSearching && totalItems === 0 && totalEntries === 0) { %>
      <%= _t('dashboard.views.dashboard.content_controller.templates.content_no_results.zero_found', {tag: tag, type: type}) %>
    <% } %>

    <% if (page === 1 && !isSearching && !liked && totalItems === 0 && totalEntries === 0) { %>
      <%= _t('dashboard.views.dashboard.content_controller.templates.content_no_results.there_are_no') %><%- shared === "only" ? 'shared' : '' %> <%- locked ? 'locked' : '' %> <%- type %>
    <% } %>
  </h4>
  <p class="CDB-Text CDB-Size-medium u-altTextColor">
    <% if (page > 1 || totalItems === 0 && totalEntries > 0) { %>
      <%= _t('dashboard.views.dashboard.content_controller.templates.content_no_results.back_to_first') %>
    <% } %>

    <% if (isSearching && totalItems === 0 && totalEntries === 0) { %>
      <%= _t('dashboard.views.dashboard.content_controller.templates.content_no_results.back_to') %><a class="ContentResult-urlLink" href="<%- defaultUrl %>"><%- type %></a>
    <% } %>

    <% if (!liked && !isSearching && totalItems === 0 && totalEntries === 0) { %>
      <%= _t('dashboard.views.dashboard.content_controller.templates.content_no_results.no_fun', {type: type}) %>
    <% } %>

    <% if (liked && totalEntries === 0 ) { %>
      <%= _t('dashboard.views.dashboard.content_controller.templates.content_no_results.fill_this', {type: type}) %>
    <% } %>
  </p>
</div>
