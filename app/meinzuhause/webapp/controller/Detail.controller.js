sap.ui.define([
  "./BaseController",
  "../model/formatter"
], (BaseController, formatter) => {
  "use strict";

  return BaseController.extend("wohnportal.meinzuhause.controller.Detail", {
    formatter,

    onInit() {
      this.getRouter().getRoute("detail").attachPatternMatched(this._onMatched, this);
    },

    _onMatched(oEvent) {
      const sPath = `/MyRequest(${oEvent.getParameter("arguments").requestUuid})`;
      const oElementBinding = this.getView().getElementBinding();

      if (oElementBinding && oElementBinding.getPath() === sPath) {
        oElementBinding.refresh(); // same request again: get the latest status
      } else {
        this.getView().bindElement({ path: sPath });
      }
    }
  });
});
