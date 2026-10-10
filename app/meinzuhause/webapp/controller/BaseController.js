sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/core/routing/History",
  "sap/ui/core/UIComponent"
], (Controller, History, UIComponent) => {
  "use strict";

  return Controller.extend("wohnportal.meinzuhause.controller.BaseController", {
    getRouter() {
      return UIComponent.getRouterFor(this);
    },

    getModel(sName) {
      return this.getView().getModel(sName);
    },

    setModel(oModel, sName) {
      this.getView().setModel(oModel, sName);
      return this;
    },

    getText(sKey, aArgs) {
      return this.getOwnerComponent().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
    },

    onNavBack() {
      if (History.getInstance().getPreviousHash() !== undefined) {
        window.history.go(-1);
      } else {
        this.getRouter().navTo("home", {}, undefined, true);
      }
    }
  });
});
