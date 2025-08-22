import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.11.1", () => {
  const DEFAULT_INTERVAL = 15;
  let intervalSec = DEFAULT_INTERVAL;

  function readIntervalFromMeta() {
    // fallback – interval setting is not critical for this poller
    return intervalSec;
  }

  function check() {
    fetch("/maintenance/status.json", { credentials: "same-origin" })
      .then((r) => (r.ok ? r.json() : { enabled: true }))
      .then((d) => {
        if (d && typeof d.interval === "number") {
          intervalSec = d.interval || DEFAULT_INTERVAL;
        }
        if (d && d.enabled) {
          if (window.location.pathname !== "/maintenance") {
            window.location.replace("/maintenance");
          }
        }
      })
      .catch(() => {});
  }

  // initial check + polling
  check();
  setInterval(check, readIntervalFromMeta() * 1000);
});
