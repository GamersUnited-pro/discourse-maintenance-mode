// Auto-redirect when maintenance ends (CSP safe)
(function() {
  function poll() {
    fetch("/site_settings/maintenance_mode_enabled.json", { credentials: "same-origin" })
      .then(r => r.ok ? r.json() : { maintenance_mode_enabled: true })
      .then(d => {
        if (d && d.maintenance_mode_enabled === false) {
          window.location.replace("/");
        }
      })
      .catch(()=>{});
  }

  var intervalSec = 15; // default, will be replaced by Rails ERB if used in maintenance page
  setInterval(poll, intervalSec * 1000);
})();
