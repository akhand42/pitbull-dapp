'use strict';

const bignum = require('bignum');

module.exports = function (chai) {
  chai.util.overwriteMethod(chai.Assertion.prototype, 'equal', function (_super) {
    return function (expected) {
      const obj = chai.util.flag(this, 'object');
      if(obj && bignum.isBigNum(obj)) {
        if(typeof expected === 'number') {
          return new chai.Assertion(obj.toString()).to.equal(String(expected));
        } else if(typeof expected === 'string') {
          return new chai.Assertion(obj.toString()).to.equal(String(expected));
        } else if(bignum.isBigNum(expected)) {
          return new chai.Assertion(expected.cmp(obj)).to.equal(0);
        }
      }
      return _super.apply(this, arguments);
    };
  });
};
