import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.11.1", (api) => {
  const DEFAULT_INTERVAL = 15;
  let intervalSec = DEFAULT_INTERVAL;

  function readIntervalFromMeta() {
    return intervalSec;
  }

  function check() {
    fetch("/maintenance/status.json", { credentials: "same-origin" })
      .then((r) => (r.ok ? r.json() : { enabled: true }))
      .then((d) => {
        if (d && typeof d.interval === "number") {
          intervalSec = d.interval || DEFAULT_INTERVAL;
        }

        // Only redirect logged-in non-staff users
        if (d && d.enabled) {
          const user = api.getCurrentUser();
          if (user && !user.staff) {
            if (window.location.pathname !== "/maintenance") {
              window.location.replace("/maintenance");
            }
          }
        }
      })
      .catch(() => {});
  }

  check();
  setInterval(check, readIntervalFromMeta() * 1000);
});
