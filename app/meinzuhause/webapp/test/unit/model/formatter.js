sap.ui.define([
  "wohnportal/meinzuhause/model/formatter"
], (formatter) => {
  "use strict";

  QUnit.module("formatter.statusState");

  QUnit.test("criticality 1 shows the request in red", (assert) => {
    assert.strictEqual(formatter.statusState(1), "Error");
  });

  QUnit.test("criticality 2 shows the request in orange", (assert) => {
    assert.strictEqual(formatter.statusState(2), "Warning");
  });

  QUnit.test("criticality 3 shows the request in green", (assert) => {
    assert.strictEqual(formatter.statusState(3), "Success");
  });

  QUnit.test("OData may deliver the number as a string", (assert) => {
    assert.strictEqual(formatter.statusState("1"), "Error");
    assert.strictEqual(formatter.statusState("3"), "Success");
  });

  QUnit.test("anything else stays neutral", (assert) => {
    assert.strictEqual(formatter.statusState(0), "None");
    assert.strictEqual(formatter.statusState(5), "None");
    assert.strictEqual(formatter.statusState(null), "None");
    assert.strictEqual(formatter.statusState(undefined), "None");
  });
});
