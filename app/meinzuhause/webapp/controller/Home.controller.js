sap.ui.define([
  "./BaseController",
  "sap/ui/model/json/JSONModel"
], (BaseController, JSONModel) => {
  "use strict";

  return BaseController.extend("wohnportal.meinzuhause.controller.Home", {
    onInit() {
      this.setModel(new JSONModel({ loaded: false, hasHome: false, loadError: false }), "homeView");
    },

    // Fired when MyHome has been read: decides between the address card and the "no contract" hint
    onHomeDataReceived(oEvent) {
      const oViewModel = this.getModel("homeView");
      oViewModel.setProperty("/loaded", true);
      oViewModel.setProperty("/loadError", !!oEvent.getParameter("error"));
      oViewModel.setProperty("/hasHome", oEvent.getSource().getLength() > 0);
    },

    onReport() {
      this.getRouter().navTo("report");
    },

    onMyRequests() {
      this.getRouter().navTo("myRequests");
    }
  });
});
