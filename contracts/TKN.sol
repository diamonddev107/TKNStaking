// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TKN is IERC20 {

    address public owner;
    string public name;
    string public symbol;
    uint256 public override totalSupply;
    uint8 constant public decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply * (10 ** decimals);
        balances[msg.sender] = totalSupply;
    }

    function allowance(address _owner, address spender) external view override returns (uint256){
        return allowed[_owner][spender];
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }    
    function approve(address _spender, uint256 _amount) public override returns (bool) {
        require(_spender != address(0), "zero address");
        require(balances[msg.sender] >= _amount, "low balance");        
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        require(_to!= address(0), "zero address");
        require(balances[msg.sender] >= _amount, "required balance is greater than sending amount");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _owner, address _spender, uint256 _amount) public override returns (bool) {
        require(_spender != address(0), "zero address");
        require(allowed[_owner][_spender] >= 0, "zero address");
        require(balances[_owner] >= _amount, "balance is lower than the amount");
        balances[_owner] -= _amount;
        balances[_spender] += _amount;  
        allowed[_owner][_spender] -= _amount;
        emit Transfer(_owner, _spender, _amount);
        return true;
    }

    function transferOwnership(address _to) external onlyOwner {
        require(_to != address(0), "zero address");
        owner = _to;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
}