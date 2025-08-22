// maintenance-refresh.js
(function() {
  const intervalSec = gon.maintenanceRefreshInterval || 15;

  function poll() {
    fetch("/site_settings/maintenance_mode_enabled.json", { credentials: "same-origin" })
      .then(r => r.ok ? r.json() : { maintenance_mode_enabled: true })
      .then(d => {
        if (d.maintenance_mode_enabled === false) {
          window.location.reload();
        }
      })
      .catch(() => { /* ignore network errors */ });
  }

  setInterval(poll, intervalSec * 1000);
})();
