const { expect } = require("chai");
const hre = require("hardhat");

describe("Deterministic deploy", function () {
    it("should deploy to ...",async function () {
        const Create3Factory = await hre.ethers.getContractFactory("Create3Factory");
        const create3factory = await Create3Factory.deploy()
        await create3factory.deployTransaction.wait();
        console.log("Deployed Create3Factory to %s", create3factory.address);
        const proxyCreationCode = '0x67363d3d37363d34f03d5260086018f3';
        const proxyCode = '0x363d3d37363d34f0';

        const salt = '0x0000000000000000000000000000000000000000000000000000000000000000';

        const addr = await create3factory.privateAddressOf(salt);
        await create3factory.privateDeploy(salt, proxyCreationCode);
        const bytecode = await hre.ethers.provider.getCode(addr);
        console.log("Expected address %s to contain code %s, got %s", addr, proxyCode, bytecode);
        expect(bytecode).to.equal(proxyCode);
    })
})