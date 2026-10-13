sap.ui.define(() => {
  "use strict";

  // One entry per test page; the test starter builds the pages from this list
  return {
    name: "QUnit test suite for Mein Zuhause",
    defaults: {
      page: "ui5://test-resources/wohnportal/meinzuhause/Test.qunit.html?testsuite={suite}&test={name}",
      qunit: {
        version: 2
      },
      ui5: {
        theme: "sap_horizon"
      },
      loader: {
        paths: {
          "wohnportal/meinzuhause": "../"
        }
      }
    },
    tests: {
      "unit/unitTests": {
        title: "Unit tests for Mein Zuhause"
      }
    }
  };
});
