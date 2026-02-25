const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ReportingContract", function () {
  let reporting;
  let owner;
  let addr1; // Constract được uỷ quyền
  let addr2; // Người nhận chi tiêu

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const Reporting = await ethers.getContractFactory("ReportingContract");
    reporting = await Reporting.deploy();
    await reporting.waitForDeployment();
  });

  it("Owner should be deployer", async function () {
    expect(await reporting.owner()).to.equal(owner.address);
  });

  it("Only owner can set authorized contract", async function () {
    await reporting.setAuthorizedContract(addr1.address, true);

    expect(await reporting.authorizedContracts(addr1.address)).to.equal(true);

    await expect(
      reporting.connect(addr1).setAuthorizedContract(addr2.address, true)
    ).to.be.revertedWith("Not owner");
  });

  it("Authorized contract can update donations", async function () {
    await reporting.setAuthorizedContract(addr1.address, true);

    await reporting.connect(addr1).updateTotalDonations(100);

    const report = await reporting.getReport();
    expect(report.totalDonations).to.equal(100);
  });

  it("Should record expense correctly", async function () {
    await reporting.setAuthorizedContract(addr1.address, true);

    await reporting
      .connect(addr1)
      .recordExpense(addr2.address, 50, "Flood");

    const total = await reporting.getTotalExpenses();
    expect(total).to.equal(50);

    const history = await reporting.getExpenseHistory(addr2.address);
    expect(history.length).to.equal(1);
    expect(history[0].amount).to.equal(50);
  });

  it("Non-authorized should fail recording expense", async function () {
    await expect(
      reporting.recordExpense(addr2.address, 50, "Flood")
    ).to.be.revertedWith("Not authorized contract");
  });
});