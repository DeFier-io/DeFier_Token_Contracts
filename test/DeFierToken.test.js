const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectRevert } = require('@openzeppelin/test-helpers');

const { expect } = require('chai');

const MyContract = contract.fromArtifact('DeFierToken');

const name = "DeFier";
const symbol = "DFR";
const totalSupply = new BN("4000000000000000000000000");

describe('token test', function () {
    const [owner, recipient, newAddress] = accounts;

    beforeEach(async function () {
        token = await MyContract.new({ from: owner });
    });

    describe('default ERC20 functions', async function () {

        it('should return the name', async function () {
            expect(await token.name()).to.equal(name);
        });

        it('should return the symbol', async function () {
            expect(await token.symbol()).to.equal(symbol);
        });

        it('should return the correct address', async function () {
            expect(await token.deFierAddress()).to.equal(owner);
        });

        it('should return the correct balance', async function () {
            expect(await token.balanceOf(owner)).to.be.bignumber.equal(totalSupply);
        });

        it('should return the decimals', async function () {
            const decimals = new BN("18");
            expect(await token.decimals()).to.be.bignumber.equal(decimals);
        });

        it('should return the totalSupply', async function () {
            expect(await token.totalSupply()).to.be.bignumber.equal(totalSupply);
        });

        it('should transfer the requested amount, burn and send the fee', async function () {
            const amount = new BN("100000000000000000000");
            const newAdminAmount = new BN("3999901000000000000000000");
            const recipientAmount = new BN("98000000000000000000");
            const newTotalSupply = new BN("3999999000000000000000000");

            await token.transfer(recipient, amount, { from: owner });
            expect(await token.balanceOf(owner)).to.be.bignumber.equal(newAdminAmount);
            expect(await token.balanceOf(recipient)).to.be.bignumber.equal(recipientAmount);
            expect(await token.totalSupply()).to.be.bignumber.equal(newTotalSupply);
        });

        it('should transfer the requested amount without burn and send fees', async function () {
            const amount = new BN("100000000000000000000");
            const newAdminAmount = new BN("3999900000000000000000000");

            await token.tranferNoFeeNoBurn(owner, recipient, amount, { from: owner });
            expect(await token.balanceOf(owner)).to.be.bignumber.equal(newAdminAmount);
            expect(await token.balanceOf(recipient)).to.be.bignumber.equal(amount);
            expect(await token.totalSupply()).to.be.bignumber.equal(totalSupply);
        });

        it('should change the burn', async function () {
            const burn_rate = new BN("250");

            await token.setBurnRate(burn_rate, { from: owner });
            expect(await token.burnRate()).to.be.bignumber.equal(burn_rate);
        });

        it('should change the fee', async function () {
            const fee_rate = new BN("250");

            await token.setFeeRate(fee_rate, { from: owner });
            expect(await token.feeRate()).to.be.bignumber.equal(fee_rate);
        });

        it('should change the deFierAddress', async function () {
            await token.changeDeFierAddress(newAddress, { from: owner });
            expect(await token.deFierAddress()).to.equal(newAddress);
        });

        it('should revert if caller is not the governance Address', async function () {
            await expectRevert(token.changeDeFierAddress(newAddress, { from: newAddress }),
                "DeFierToken: must have governance role to changeDeFierAddress");
        });

    })
});