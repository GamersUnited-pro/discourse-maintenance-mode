import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.11.1", (api) => {
  api.modifyClass("controller:adminPlugins", {
    pluginCurrentVersion: null,
    pluginLatestVersion: null,

    get pluginUpdateAvailable() {
      return (
        this.pluginLatestVersion &&
        this.pluginCurrentVersion &&
        this.pluginLatestVersion !== this.pluginCurrentVersion
      );
    },

    actions: {
      // nothing extra needed, unless you want a dismiss button
    },
  });

  // Fetch from PluginStore
  fetch("/admin/plugins/discourse-maintenance-mode/version.json")
    .then((r) => r.json())
    .then((data) => {
      api.container.lookup("controller:adminPlugins").setProperties({
        pluginCurrentVersion: data.current_version,
        pluginLatestVersion: data.latest_version,
      });
    });
});
