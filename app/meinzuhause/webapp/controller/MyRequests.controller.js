sap.ui.define([
  "./BaseController",
  "../model/formatter"
], (BaseController, formatter) => {
  "use strict";

  return BaseController.extend("wohnportal.meinzuhause.controller.MyRequests", {
    formatter,

    onInit() {
      this.getRouter().getRoute("myRequests").attachPatternMatched(this._onMatched, this);
    },

    // The list loads itself the first time; later visits refresh it so new requests and status changes show up
    _onMatched() {
      if (this._bVisited) {
        this.byId("requestList").getBinding("items").refresh();
      }
      this._bVisited = true;
    },

    onRefresh() {
      const oBinding = this.byId("requestList").getBinding("items");
      oBinding.attachEventOnce("dataReceived", () => this.byId("pullToRefresh").hide());
      oBinding.refresh();
    },

    onRequestPress(oEvent) {
      const oContext = oEvent.getSource().getBindingContext();
      this.getRouter().navTo("detail", { requestUuid: oContext.getProperty("RequestUUID") });
    },

    onReport() {
      this.getRouter().navTo("report");
    }
  });
});
