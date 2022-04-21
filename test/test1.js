
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StakingContract Test", function () {
    
  it("StakingContract Test starts", async function () {
    
    const [owner, addr1, addr2, bountyWallet] = await ethers.getSigners();
    const TKN_Token = await ethers.getContractFactory("TKN");
    const tkn = await TKN_Token.deploy("TKN token", "TKN", ethers.utils.parseUnits('10000', 'ether'));
    const tokenAddress = tkn.address;

    const bountyValue = ethers.utils.parseUnits('100', 'ether');

    await tkn.transfer(bountyWallet.address, bountyValue);
    await tkn.transfer(addr1.address, bountyValue);

    const getbalance = async(address) => {

      let balance = await tkn.balanceOf(address);
      return balance;
    }
    
    const StakingContract = await ethers.getContractFactory("StakingPlatform");
    const stakingContract = await StakingContract.deploy(tkn.address); 

    const stakeAmount = ethers.utils.parseUnits('10', 'ether');

    let b = await getbalance(addr1.address);

    console.log("initial balance...", b);
    
    await tkn.connect(addr1).approve(stakingContract.address, stakeAmount);
    await stakingContract.connect(addr1).stake(stakeAmount);
    
    let stakedamount = await stakingContract.connect(addr1).stakedAmount(addr1.address);
    b = await getbalance(addr1.address);
    
    console.log("staked amount...", stakedamount);
    console.log("balance after staking...", b);
    
    await stakingContract.connect(addr1).withdraw(stakeAmount);
    
    stakedamount = await stakingContract.connect(addr1).stakedAmount(addr1.address);
    b = await getbalance(addr1.address);
    
    console.log("staked amount after withdraw...", stakedamount);
    console.log("balance after unstaking...", b);
  });
  
});