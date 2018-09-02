<div class="IntermediateInfo">
  <div class="LayoutIcon LayoutIcon--negative">
    <i class="CDB-IconFont CDB-IconFont-cockroach"></i>
  </div>
  <h4 class="CDB-Text CDB-Size-large u-mainTextColor u-secondaryTextColor u-bSpace--m u-tSpace-xl"><%= _t('dashborad.components.fail.error') %></h4>
  <% if (msg) { %>
    <p class="CDB-Text CDB-Size-medium u-altTextColor"><%= msg %></p>
  <% } %>
  <p class="CDB-Text CDB-Size-medium u-altTextColor"><%= _t('dashborad.components.fail.contact') %></p>
</div>
