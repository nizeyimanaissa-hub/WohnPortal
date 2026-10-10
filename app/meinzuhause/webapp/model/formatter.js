sap.ui.define([], () => {
  "use strict";

  return {
    /**
     * Maps the backend criticality (StatusCriticality) to a UI5 value state.
     * 1 = red, 2 = orange, 3 = green, everything else neutral.
     */
    statusState(vCriticality) {
      switch (Number(vCriticality)) {
        case 1:
          return "Error";
        case 2:
          return "Warning";
        case 3:
          return "Success";
        default:
          return "None";
      }
    }
  };
});
