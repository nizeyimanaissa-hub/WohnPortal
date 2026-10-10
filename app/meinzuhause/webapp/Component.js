sap.ui.define([
  "sap/ui/core/UIComponent",
  "sap/ui/Device",
  "sap/ui/model/json/JSONModel"
], (UIComponent, Device, JSONModel) => {
  "use strict";

  return UIComponent.extend("wohnportal.meinzuhause.Component", {
    metadata: {
      manifest: "json",
      interfaces: ["sap.ui.core.IAsyncContentCreation"]
    },

    init() {
      UIComponent.prototype.init.apply(this, arguments);

      // Device info for the views, e.g. pull-to-refresh only on touch devices
      const oDeviceModel = new JSONModel(Device);
      oDeviceModel.setDefaultBindingMode("OneWay");
      this.setModel(oDeviceModel, "device");

      this.getRouter().initialize();
    },

    getContentDensityClass() {
      return Device.support.touch ? "sapUiSizeCozy" : "sapUiSizeCompact";
    }
  });
});
