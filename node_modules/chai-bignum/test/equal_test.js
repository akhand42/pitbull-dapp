'use strict';

const expect = require('chai').expect;

const bignum = require('bignum');

describe('Equal', function () {
  it('should check equality', function () {
    expect(bignum('1234')).to.equal(1234);
    expect(bignum('12342239499494')).to.equal(bignum('12342239499494'));
  });
});
