// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingPlatform is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // args for _stakers
    struct Staker {
        uint256 stakerCurrentReward;
        uint256 stakedAmount;
        uint256 stakeStartTime;
        uint256 lastUpdatedTime;
    }   
    
    uint256 private _earlyUnstakingFeeRate;
    uint256 private _rewardRate;
    uint256 private _rewardFeeRate;
    uint256 private _lockupPeriod;
    uint256 private _unstakingFeeRate;
    
    address[] private _stakers;

    mapping(address => Staker) private _staker;

    // Total amount of token staked in staking pool.
    uint256 public totalStaked;
    IERC20 public token;
    
    // Events triggered when start, stake, unstake(withdraw), get reward.
    event Staked(address staker, uint256 amount);
    event Harvest(address staker, uint256 rewardToClaim);
    event Withdraw(address staker, uint256 amount);

    constructor(address _token) {
        
        Init();
        token = IERC20(_token);
    }

    function Init() private {

        _earlyUnstakingFeeRate = 1500; // 15 % of early unstaking fee
        _unstakingFeeRate = 200; // 2 % of unstaking fee after lockup time
        _lockupPeriod = 90; // 90 days
        _rewardFeeRate = 500;  // 5 %
        _rewardRate = 200; // daily 2%
    }

    // Update rewards for _stakers according to deposited amount.
    function updateReward() private{
        
        uint256 stakerStakedAmount = _staker[msg.sender].stakedAmount;
        
        uint256 newReward = stakerStakedAmount.mul(block.timestamp.sub(_staker[msg.sender].lastUpdatedTime)).mul(_rewardRate).div(1 days).div(1e4);
        _staker[msg.sender].stakerCurrentReward = _staker[msg.sender].stakerCurrentReward.add(newReward);
        _staker[msg.sender].lastUpdatedTime = block.timestamp;
    }
    
    // Staker tries to stake specific amount of token.
   function stake(uint256 _amount) public{
        
        require(_amount > 0, "Amount should be greater than 0");
        require(token.balanceOf(msg.sender) > _amount, "Insufficient!");
        
        updateReward();
        
        token.safeTransferFrom(msg.sender, address(this), _amount);
        _staker[msg.sender].stakedAmount = _staker[msg.sender].stakedAmount.add(_amount);
        
        if (!_staker[msg.sender].isStaker){

            _staker[msg.sender].stakeStartTime = block.timestamp;
            _staker[msg.sender].isStaker = true;
        }
        totalStaked = totalStaked.add(_amount);
        
        emit Staked(msg.sender, _amount);
    }

    function getTotalStaked() public view returns (uint256) {

        return totalStaked;
    }

    function getNumberofStakers() public view returns (uint256) {

        return _stakers.length;
    }
    
    function stakedAmount(address _address) public view returns (uint256) {
        
        return _staker[_address].stakedAmount;
    }

    function getRewardRate() public view returns (uint256) {

        return _rewardRate;
    }

    function lockupPeriod() public view returns (uint256) {
        
        return _lockupPeriod;
    }

    // Amount of reward staker can be guaranteed. 
    function rewardToHarvest(address _address) public view returns (uint256){
        
        uint256 stakerStakedAmount = _staker[_address].stakedAmount;
        uint256 newReward = stakerStakedAmount.mul(block.timestamp.sub(_staker[_address].lastUpdatedTime)).mul(_rewardRate).div(1 days).div(1e4);
        
        return _staker[msg.sender].stakerCurrentReward + newReward; // not update staker's current reward as it will spend gas fee. When staker tries to harvest, it is updated. This is just to see on frontend side in real time 
    }

    // Withdraw some of token staked.
    function withdraw(uint256 amount) external{
        
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _staker[msg.sender].stakedAmount, "Invalid amount");

        updateReward();
        uint256 amountTobeWithdrawn = amount >= token.balanceOf(address(this)) ? token.balanceOf(address(this)) : amount;
        uint256 fee = _unstakingFeeRate;
        bool isLockupTimeOver = block.timestamp >= _staker[msg.sender].stakeStartTime.add(_lockupPeriod.mul(1 days));
        if (!isLockupTimeOver) {
            fee = _earlyUnstakingFeeRate;
        }
        _staker[msg.sender].stakedAmount = _staker[msg.sender].stakedAmount.sub(amountTobeWithdrawn);
        totalStaked = totalStaked.sub(amountTobeWithdrawn);
        amountTobeWithdrawn = amountTobeWithdrawn.sub(amountTobeWithdrawn.mul(fee).div(1e4));
        token.safeTransfer(msg.sender, amountTobeWithdrawn);
        
        emit Withdraw(msg.sender, amountTobeWithdrawn);
    }

    // Get reward of msg.sender
    function harvest() public{
        
        updateReward();
        
        uint256 curReward = _staker[msg.sender].stakerCurrentReward;

        if (curReward >= token.balanceOf(address(this)))
            curReward = token.balanceOf(address(this));

        uint256 rewardToClaim = curReward.sub(curReward.mul(_rewardFeeRate).div(1e4));
        
        require(rewardToClaim > 0, "Nothing to claim");
        if (rewardToClaim > token.balanceOf(address(this)))
            rewardToClaim = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, rewardToClaim);
        _staker[msg.sender].stakerCurrentReward = 0;
        
        emit Harvest(msg.sender, rewardToClaim);
    }
    
    function setRewardRate(uint256 __rewardRate) external onlyOwner {
        
        require(__rewardRate > 0, "Invalid value");
        
        _rewardRate = __rewardRate;
    }
    
    function setUnstakingFeeRate(uint256 __unstakingFeeRate) external onlyOwner {
        
        require(__unstakingFeeRate > 0, "Invalid Unstaking Fee Rate");

        _unstakingFeeRate = __unstakingFeeRate;
    }

    function setEarlyUnstakingFeeRate(uint256 __earlyUnstakingFeeRate) external onlyOwner {
        
        require(__earlyUnstakingFeeRate > 0, "Invalid Unstaking Fee Rate");

        _earlyUnstakingFeeRate = __earlyUnstakingFeeRate;
    }

    function setLockupTime(uint256 lockupTime) external onlyOwner {
        
        require(lockupTime > 0, "Can't be zero");
        
        _lockupPeriod = lockupTime;
    }
    
    
}