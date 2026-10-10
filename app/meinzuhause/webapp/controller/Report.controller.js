sap.ui.define([
  "./BaseController",
  "sap/ui/model/json/JSONModel",
  "sap/ui/core/Messaging",
  "sap/m/MessageBox",
  "sap/m/MessageToast"
], (BaseController, JSONModel, Messaging, MessageBox, MessageToast) => {
  "use strict";

  const MIN_DESCRIPTION = 20; // same rule as the backend validation

  return BaseController.extend("wohnportal.meinzuhause.controller.Report", {
    onInit() {
      this.setModel(new JSONModel(), "reportView");
      this.getRouter().getRoute("report").attachPatternMatched(this._reset, this);
    },

    // Every visit starts with an empty form on step 1
    _reset() {
      this.getModel("reportView").setData({
        category: "",
        categoryText: "",
        title: "",
        description: "",
        descriptionHint: this.getText("descriptionMissing", [MIN_DESCRIPTION]),
        busy: false
      });

      const oWizard = this.byId("reportWizard");
      const oFirstStep = this.byId("stepCategory");
      oWizard.discardProgress(oFirstStep);
      oWizard.goToStep(oFirstStep);
      this.byId("categoryList").removeSelections(true);
    },

    onCategorySelect(oEvent) {
      const oContext = oEvent.getParameter("listItem").getBindingContext();
      const oViewModel = this.getModel("reportView");
      oViewModel.setProperty("/category", oContext.getProperty("Category"));
      oViewModel.setProperty("/categoryText", oContext.getProperty("CategoryText"));
    },

    onDescriptionChange(oEvent) {
      const iMissing = MIN_DESCRIPTION - oEvent.getParameter("value").length;
      this.getModel("reportView").setProperty("/descriptionHint", iMissing > 0
        ? this.getText("descriptionMissing", [iMissing])
        : this.getText("descriptionOk"));
    },

    // Last wizard button ("Meldung absenden"): create the request in the backend
    async onWizardComplete() {
      const oViewModel = this.getModel("reportView");
      const oData = oViewModel.getData();
      const oModel = this.getModel();

      // One list binding for all attempts, with its own update group,
      // so the POST is sent exactly when we call submitBatch
      if (!this._oCreateBinding) {
        this._oCreateBinding = oModel.bindList("/MyRequest", undefined, undefined, undefined, {
          $$updateGroupId: "reportGroup"
        });
      }
      Messaging.removeAllMessages();

      // Tenant and apartment are not sent: the backend fills them in from the login.
      // bSkipRefresh = true: the POST response already contains the new request
      const oContext = this._oCreateBinding.create({
        Category: oData.category,
        Title: oData.title,
        Description: oData.description
      }, true);
      oContext.created().catch(() => {
        // rejected only when we reset the failed entry (see below)
      });

      oViewModel.setProperty("/busy", true);
      try {
        await oModel.submitBatch("reportGroup");
      } catch (oError) {
        console.error("[MeinZuhause] batch failed:", oError);
      } finally {
        oViewModel.setProperty("/busy", false);
      }

      // Still transient = the backend refused it (e.g. a validation error)
      if (oContext.isTransient()) {
        await this._showBackendMessages();
        // Remove the failed entry from the queue, so the next attempt starts clean
        await this._oCreateBinding.resetChanges().catch(() => {});
        return;
      }

      const [sRequestId, sRequestUuid] = await oContext.requestProperty(["RequestID", "RequestUUID"]);
      MessageToast.show(this.getText("reportSent", [sRequestId]));
      this.getRouter().navTo("detail", { requestUuid: sRequestUuid }, true);
    },

    async _showBackendMessages() {
      // The model reports backend errors to the message model right after the
      // batch response; wait one tick so they are all there
      await new Promise((resolve) => setTimeout(resolve, 0));
      const aMessages = Messaging.getMessageModel().getData();
      aMessages.forEach((oMessage) => {
        // Full details for the developer: F12 -> Console
        console.error("[MeinZuhause] backend message:", oMessage.getMessage(), oMessage.getTechnicalDetails && oMessage.getTechnicalDetails());
      });
      const aTexts = [...new Set(aMessages.map((oMessage) => oMessage.getMessage()))];
      MessageBox.error(aTexts.length ? aTexts.join("\n") : this.getText("reportFailed"));
      Messaging.removeAllMessages();
    }
  });
});