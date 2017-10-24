/*
file:   Hut34ICO.sol
ver:    0.2.0
author: Darryl Morris
date:   20-Oct-2017
email:  o0ragman0o AT gmail.com
(c) Darryl Morris 2017

A collated contract set for the receipt of funds and production of ERC20 tokens
as specified by Hut34.

License
-------
This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

Release Notes
-------------
*/


pragma solidity ^0.4.13;

contract Hut34Config
{
    // ERC20 token name
    string  public constant name            = "Hut34 Entropy Token";
    
    // ERC20 trading symbol
    string  public constant symbol          = "ENT";

    // ERC20 decimal places
    uint8   public constant decimals        = 18;

    // Total supply (* in unit ENT *)
    uint    public constant TOTAL_TOKENS    = 100000000;

// TODO: uncomment and configure actual address
    // Contract owner.
    // address public constant OWNER           = 0x0;
    address public          OWNER           = msg.sender;
    
// TODO: uncomment correct date. Set as `constant`
    // + new Date("00:00 2 November 2017")/1000
    // uint    public constant START_DATE      = 1509544800;
    uint    public          START_DATE      = now + 1 minutes;

// TODO: configure actual address
    // A Hut34 address to own tokens
    address public constant HUT34_ADDRESS   = 0x1;
    
// TODO: configure actual address
    // A Hut34 address to accept raised funds
    address public constant HUT34_WALLET    = 0x2;
    
    // Percentage of tokens to be vested over 2 years. 20%
    uint    public constant VESTED_PERCENT  = 20;

// TODO: uncomment correct period    
    // Vesting period
    // uint    public constant VESTING_PERIOD  = 26 weeks;
    uint    public constant VESTING_PERIOD  = 2 minutes;

// TODO: Hut34 to advise on minimum cap
    // Minimum cap over which the funding is considered successful
    uint    public constant MIN_CAP         = 4000 * 1 ether;

// TODO: Hut34 to advise on KYC threshold    
    // An ether threshold over which a funder must KYC before tokens can be
    // transferred (unit of ether);
    uint    public constant KYC_THRESHOLD   = 40 * 1 ether;

    // A minimum amount of ether funding before the concierge rate is applied
    // to tokens
    uint    public constant WHOLESALE_THRESHOLD  = 150 * 1 ether;
    
    // Number of tokens up for wholesale purchasers (* in unit ENT *)
    uint    public constant WHOLESALE_TOKENS = 12500000;

// TODO: Hut34 to advise number of presold tokens
    // Tokens sold to prefunders (* in unit ENT *)
    uint    public constant PRESOLD_TOKENS  = 12000000;

// TODO: Hut34 to provide wallet address for bulk transfer of presale tokens.
    // Address holding presold tokens to be distributed after ICO
    address public constant PRESOLD_ADDRESS = 0x1;
    
// TODO: Hut34 to advise on actual wholesale rate
    // wholesale rate for purchases over WHOLESALE_THRESHOLD ether
    uint    public constant RATE_WHOLESALE  = 900;

    // Time dependant retail rates
    // Day 1
    uint    public constant RATE_DAY_0      = 750;

    // Week 1
    uint    public constant RATE_DAY_1      = 652;

    // Week 2
    uint    public constant RATE_DAY_7      = 588;

    // Week 3
    uint    public constant RATE_DAY_14     = 545;

    // Week 4
    uint    public constant RATE_DAY_21     = 517;

    // Week 5
    uint    public constant RATE_DAY_28     = 500;
}


library SafeMath
{
    // a add to b
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }
    
    // a subtract b
    function sub(uint a, uint b) internal pure returns (uint c) {
        c = a - b;
        assert(c <= a);
    }
    
    // a multiplied by b
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }
    
    // a divided by b
    function div(uint a, uint b) internal pure returns (uint c) {
        assert(b != 0);
        c = a / b;
    }
}


contract ReentryProtected
{
    // The reentry protection state mutex.
    bool __reMutex;

    // Sets and clears mutex in order to block function reentry
    modifier preventReentry() {
        require(!__reMutex);
        __reMutex = true;
        _;
        delete __reMutex;
    }

    // Blocks function entry if mutex is set
    modifier noReentry() {
        require(!__reMutex);
        _;
    }
}


contract ERC20Token
{
    using SafeMath for uint;

/* Constants */

    // none
    
/* State variable */

    /// @return The Total supply of tokens
    uint public totalSupply;
    
    /// @return Tokens owned by an address
    mapping (address => uint) balances;
    
    /// @return Tokens spendable by a thridparty
    mapping (address => mapping (address => uint)) allowed;

/* Events */

    // Triggered when tokens are transferred.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount);

    // Triggered whenever approve(address _spender, uint256 _amount) is called.
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount);

/* Modifiers */

    // none
    
/* Functions */

    // Using an explicit getter allows for function overloading    
    function balanceOf(address _addr)
        public
        view
        returns (uint)
    {
        return balances[_addr];
    }
    
    // Using an explicit getter allows for function overloading    
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _amount)
        public
        returns (bool)
    {
        return xfer(msg.sender, _to, _amount);
    }

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        returns (bool)
    {
        require(_amount <= allowed[_from][msg.sender]);
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        return xfer(_from, _to, _amount);
    }

    // Process a transfer internally.
    function xfer(address _from, address _to, uint _amount)
        internal
        returns (bool)
    {
        require(_amount <= balances[_from]);

        Transfer(_from, _to, _amount);
        
        // avoid wasting gas on 0 token transfers
        if(_amount == 0) return true;
        
        balances[_from] = balances[_from].sub(_amount);
        balances[_to]   = balances[_to].add(_amount);
        
        return true;
    }

    // Approves a third-party spender
    function approve(address _spender, uint256 _amount)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
}


/*-----------------------------------------------------------------------------\

## Conditional Entry Table

Functions must throw on F conditions

Renetry prevention is on all public mutating functions
Reentry mutex set in finalizeITO(), externalXfer(), refund()

|function                |<startDate |<endDate  |fundFailed  |fundRaised|itoSucceeded
|------------------------|:---------:|:--------:|:----------:|:--------:|:---------:|
|()                      |F          |T         |F           |T         |F          |
|abort()                 |T          |T         |T           |T         |F          |
|proxyPurchase()         |F          |T         |F           |T         |F          |
|finalizeITO()           |F          |F         |F           |T         |T          |
|refund()                |F          |F         |T           |F         |F          |
|transfer()              |F          |F         |F           |F         |T          |
|transferFrom()          |F          |F         |F           |F         |T          |
|approve()               |F          |F         |F           |F         |T          |
|clearKyc()              |T          |T         |T           |T         |T          |
|releaseVested()         |F          |F         |F           |F         |now>release|
|changeOwner()           |T          |T         |T           |T         |T          |
|acceptOwnership()       |T          |T         |T           |T         |T          |
|transferExternalTokens()|T          |T         |T           |T         |T          |
|destroy()               |F          |F         |!__abortFuse|F         |F          |

\*----------------------------------------------------------------------------*/

contract Hut34ICOAbstract
{
    /// @dev Logged upon receiving a deposit
    /// @param _from The address from which value has been recieved
    /// @param _value The value of ether received
    event Deposit(address indexed _from, uint _value);
    
    /// @dev Logged upon a withdrawal
    /// @param _by the address of the withdrawer
    /// @param _to Address to which value was sent
    /// @param _value The value in ether which was withdrawn
    event Withdrawal(address indexed _by, address indexed _to, uint _value);

    /// @dev Logged upon refund
    /// @param _to Address to which value was sent
    /// @param _value The value in ether which was withdrawn
    event Refunded(address indexed _to, uint _value);
    
    /// @dev Logged when new owner accepts ownership
    /// @param _from the old owner address
    /// @param _to the new owner address
    event ChangedOwner(address indexed _from, address indexed _to);
    
    /// @dev Logged when owner initiates a change of ownership
    /// @param _to the new owner address
    event ChangeOwnerTo(address indexed _to);
    
    /// @dev Logged when a funder exceeds the KYC limit
    /// @param _addr The address that must clear KYC before tokens are unlocked
    event MustKyc(address indexed _addr);
    
    /// @dev Logged when a KYC flag is cleared against an address
    /// @param _addr The addres which has had KYC clearance
    event ClearedKyc(address indexed _addr);
    
    /// @dev Logged when vested tokens are released back to HUT32_WALLET
    /// @param _releaseDate The official release date (even if released at
    /// later date)
    event VestingReleased(uint _releaseDate);

//
// Constants
//

    // The Hut34 vesting 'psudo-address' for transferring and releasing vested
    // tokens to the Hut34 Wallet. The address is UTF8 encoding of the
    // string and can only be accessed by the 'releaseVested()' function.
    address public constant HUT34_VEST_ADDR = address(bytes20("Hut34 Vesting"));

//
// State Variables
//

    /// @dev This fuse blows upon calling abort() which forces a fail state
    /// @return the abort state. true == not aborted
    bool public __abortFuse = true;
    
    /// @dev Sets to true after the fund is swept to the fund wallet, allows
    /// token transfers and prevents abort()
    /// @return final success state of ICO
    bool public icoSucceeded;

    /// @dev An address permissioned to enact owner restricted functions
    /// @return owner
    address public owner;
    
    /// @dev An address permissioned to take ownership of the contract
    /// @return new owner address
    address public newOwner;

    /// @dev A tally of total ether raised during the funding period
    /// @return Total ether raised during funding
    uint public etherRaised;
    
    /// @return Wholesale tokens available for sale
    uint public wholesaleLeft;
    
    /// @return Total ether refunded. Used to permision call to `destroy()`
    uint public refunded;
    
    /// @returns Date of next vesting release
    uint public nextReleaseDate;

    /// @return Ether paid by an address
    mapping (address => uint) public etherContributed;
    
    /// @returns KYC flag for an address
    mapping (address => bool) public mustKyc;

//
// Modifiers
//

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

//
// Function Abstracts
//

    /// @return `true` if MIN_FUNDS were raised
    function fundRaised() public view returns (bool);
    
    /// @return `true` if MIN_FUNDS were not raised before endDate or contract 
    /// has been aborted
    function fundFailed() public view returns (bool);

    /// @return The current retail rate for token purchase
    function currentRate() public view returns (uint);
    
    /// @param _wei A value of ether in units of wei
    /// @return allTokens_ tokens returnable for the funding amount
    /// @return wholesaleToken_ Number of tokens purchased at wholesale rate
    function ethToTokens(uint _wei)
        public view returns (uint allTokens_, uint wholesaleTokens_);

    /// @notice Processes a token purchase for `_addr`
    /// @param _addr An address to purchase tokens
    /// @return Boolean success value
    /// @dev Requires 120,000 gas
    function proxyPurchase(address _addr) public payable returns (bool);

    /// @notice Finalize the ICO and transfer funds
    /// @return Boolean success value
    function finalizeICO() public returns (bool);

    /// @notice Clear the KYC flags for an array of addresses to allow tokens
    /// transfers
    function clearKyc(address[] _addrs) public returns (bool);
    
    /// @notice Release vested tokens after a maturity date
    /// @return Boolean success value
    function releaseVested() public returns (bool);

    /// @notice Claim refund on failed ITO
    /// @return Boolean success value
    function refund() public returns (bool);
    
    /// @notice Push refund for `_addr` from failed ICO
    /// @param _addrs An array of address to refund
    /// @return Boolean success value
    function refundFor(address[] _addrs) public returns (bool);

    /// @notice Abort the token sale prior to finalizeICO() 
    function abort() public returns (bool);

    /// @notice Salvage `_amount` tokens at `_kaddr` and send them to `_to`
    /// @param _kAddr An ERC20 contract address
    /// @param _to and address to send tokens
    /// @param _amount The number of tokens to transfer
    /// @return Boolean success value
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public returns (bool);
}


/*-----------------------------------------------------------------------------\

 Hut34ICO implimentation

\*----------------------------------------------------------------------------*/

contract Hut34ICO is 
    ReentryProtected,
    ERC20Token,
    Hut34ICOAbstract,
    Hut34Config
{
    using SafeMath for uint;

//
// Constants
//

    // Token fixed point for decimal places
    uint constant TOKEN = uint(10)**decimals; 

    // Calculate vested tokens
    uint public constant VESTED_TOKENS =
            TOKEN * TOTAL_TOKENS * VESTED_PERCENT / 100;
    // Hut34 retains 70% of tokens
    uint public constant RETAINED_TOKENS = TOKEN * TOTAL_TOKENS * 7 / 10;

// TODO: Use correct END_DATE calculation    
    // // Calculate end date
    // uint public constant END_DATE = START_DATE + 35 days;
    uint public END_DATE = START_DATE + 35 minutes;

// TODO: set final commission rate
    // Divides `etherRaised` to calculate commision
    // etherRaise/80 == etherRaised * 1.25% / 100
    uint public constant COMMISSION_DIV = 80;

    // Developer commission wallet
    address public constant COMMISSION_WALLET = 
        0x0065D506E475B5DBD76480bAFa57fe7C41c783af;

//
// Functions
//

    function Hut34ICO()
        public
    {
        // Run sanity checks
        require(TOTAL_TOKENS != 0);
        require(OWNER != 0x0);
        require(HUT34_ADDRESS != 0x0);
        require(HUT34_WALLET != 0x0);
        require(PRESOLD_TOKENS <= WHOLESALE_TOKENS);
        require(PRESOLD_TOKENS == 0 || PRESOLD_ADDRESS != 0x0);
        require(MIN_CAP != 0);
        require(START_DATE >= now);
        require(bytes(name).length != 0);
        require(bytes(symbol).length != 0);
        require(KYC_THRESHOLD != 0);
        require(RATE_DAY_0 >= RATE_DAY_1);
        require(RATE_DAY_1 >= RATE_DAY_7);
        require(RATE_DAY_7 >= RATE_DAY_14);
        require(RATE_DAY_14 >= RATE_DAY_21);
        require(RATE_DAY_21 >= RATE_DAY_28);
        
        owner = OWNER;
        totalSupply = TOTAL_TOKENS.mul(TOKEN);
        wholesaleLeft = WHOLESALE_TOKENS.mul(TOKEN);
        uint presold = PRESOLD_TOKENS.mul(TOKEN);
        wholesaleLeft = wholesaleLeft.sub(presold);
        // Presale raise is appoximate given it was conducted in Fiat.
        etherRaised = 1 ether * PRESOLD_TOKENS / RATE_WHOLESALE;
        
        // Load up total supply in the Hut34 admin address
        balances[HUT34_ADDRESS] = totalSupply;
        Transfer(0x0, HUT34_ADDRESS, totalSupply);
        // Transfer presold tokens to holding address;
        balances[HUT34_ADDRESS] = balances[HUT34_ADDRESS].sub(presold);
        balances[PRESOLD_ADDRESS] = balances[PRESOLD_ADDRESS].add(presold);
        Transfer(HUT34_ADDRESS, PRESOLD_ADDRESS, presold);
    }

    // Default function. Accepts payments during funding period
    function ()
        public
        payable
    {
        // Pass through to purchasing function. Will throw on failed or
        // successful ITO
        proxyPurchase(msg.sender);
    }

//
// Getters
//

    // ITO fails if aborted or minimum funds are not raised by the end date
    function fundFailed() public view returns (bool)
    {
        return !__abortFuse
            || (now > END_DATE && etherRaised < MIN_CAP);
    }
    
    // Funding succeeds if not aborted, minimum funds are raised before end date
    function fundRaised() public view returns (bool)
    {
        return !fundFailed()
            && etherRaised >= MIN_CAP;
    }

    // Returns wholesale value in wei
    function wholeSaleValueLeft() public view returns (uint)
    {
        return 1 ether * wholesaleLeft / RATE_WHOLESALE;
    }

    function currentRate()
        public
        view
        returns (uint)
    {
//TODO: uncomment production code. Delete test code         
        // return
        //     fundFailed() ? 0 :
        //     icoSucceeded ? 0 :
        //     now < START_DATE ? 0 :
        //     now < START_DATE + 1 days ? RATE_DAY_0 :
        //     now < START_DATE + 7 days ? RATE_DAY_1 :
        //     now < START_DATE + 14 days ? RATE_DAY_7 :
        //     now < START_DATE + 21 days ? RATE_DAY_14 :
        //     now < START_DATE + 28 days ? RATE_DAY_21 :
        //     now < END_DATE ? RATE_DAY_28 :
        //     0;
        return  fundFailed() ? 0 :
                icoSucceeded ? 0 :
                now < START_DATE ? 0 :
                now < START_DATE + 1 minutes ? RATE_DAY_0 :
                now < START_DATE + 7 minutes ? RATE_DAY_1 :
                now < START_DATE + 14 minutes ? RATE_DAY_7 :
                now < START_DATE + 21 minutes ? RATE_DAY_14 :
                now < START_DATE + 28 minutes ? RATE_DAY_21 :
                now < END_DATE ? RATE_DAY_28 :
                0;
    }
    
    // Calculates the sale and wholesale portion of tokens for a given value
    // of wei at the time of calling.
    function ethToTokens(uint _wei)
        public
        view
        returns (uint allTokens_, uint wholesaleTokens_)
    {
        // Get wholesale portion of ether and tokens
        uint wsValueLeft = 1 ether * wholesaleLeft / RATE_WHOLESALE;
        uint wholesaleSpend = 
            // No wholesale purchse
            _wei < WHOLESALE_THRESHOLD ? 0 :
            // Total wholesale purchase
            _wei < wsValueLeft ?  _wei :
            // over funded for remaining wholesale tokens
            wsValueLeft;
        
        wholesaleTokens_ = wholesaleSpend
                .mul(RATE_WHOLESALE)
                .mul(TOKEN)
                .div(1 ether);

        // Remaining wei used to purchase retail tokens
        _wei = _wei.sub(wholesaleSpend);

        // Get retail rate        
        uint saleRate = currentRate();

        allTokens_ = _wei
                .mul(saleRate)
                .mul(TOKEN)
                .div(1 ether)
                .add(wholesaleTokens_);
    }

//
// ICO functions
//

    // The fundraising can be aborted any time before `finaliseICO()` is called.
    // This will force a fail state and allow refunds to be collected.
    // The owner can abort or anyone else if a successful fund has not been
    // finalised before 7 days after the end date.
    function abort()
        public
        noReentry
        returns (bool)
    {
        require(!icoSucceeded);
//TODO: uncomment production code. Delete test code         
        // require(msg.sender == owner || now > END_DATE  + 7 days);
        require(msg.sender == owner || now > END_DATE  + 7 minutes);
        delete __abortFuse;
        return true;
    }
    
    // General addresses can purchase tokens during funding
    function proxyPurchase(address _addr)
        public
        payable
        noReentry
        returns (bool)
    {
        require(!fundFailed());
        require(!icoSucceeded);
        require(msg.value > 0);
        
        // Log ether deposit
        Deposit (_addr, msg.value);
        
        // Get ether to token conversion
        uint tokens;
        // Portion of tokens sold at wholesale rate
        uint wholesaleTokens;

        (tokens, wholesaleTokens) = ethToTokens(msg.value);

        // Block any failed token creation
        require(tokens > 0);

        // Prevent over subscribing 
        require(balances[HUT34_ADDRESS] - tokens >= RETAINED_TOKENS);

        // Adjust wholesale tokens left for sale
        if (wholesaleTokens != 0) {
            wholesaleLeft = wholesaleLeft.sub(wholesaleTokens);
        }
        
        // transfer tokens from fund wallet
        balances[HUT34_ADDRESS] = balances[HUT34_ADDRESS].sub(tokens);
        balances[_addr] = balances[_addr].add(tokens);
        Transfer(HUT34_ADDRESS, _addr, tokens);

        // Update funds raised
        etherRaised = etherRaised.add(msg.value);

        // Update holder payments
        etherContributed[_addr] = etherContributed[_addr].add(msg.value);

        // Check KYC requirement
        if(etherContributed[_addr] > KYC_THRESHOLD && !mustKyc[_addr]) {
            mustKyc[_addr] = true;
            MustKyc(_addr);
        }

        return true;
    }
    
    // Owner can sweep a successful funding to the fundWallet.
    // Can be called repeatedly to recover errant ether which may have been
    // `selfdestructed` to the contract
    // Contract can be aborted up until this returns `true`
    function finalizeICO()
        public
        onlyOwner
        preventReentry()
        returns (bool)
    {
        // Must have reached minimum cap
        require(fundRaised());
        
        // Lock away vested tokens
        if(!icoSucceeded) {
            // transfer vested tokens from fund wallet
            uint vested = VESTED_TOKENS;
            balances[HUT34_ADDRESS] = balances[HUT34_ADDRESS].sub(vested);
            balances[HUT34_VEST_ADDR] = balances[HUT34_VEST_ADDR].add(vested);
            Transfer(HUT34_ADDRESS, HUT34_VEST_ADDR, vested);
            nextReleaseDate = now + VESTING_PERIOD;
        }

        // Set success flag;
        icoSucceeded = true;
        
        // Transfer % Developer commission
        uint devCommission = calcCommission();
        Withdrawal(this, COMMISSION_WALLET, devCommission);
        COMMISSION_WALLET.transfer(devCommission);

        // Remaining % to the fund wallet
        Withdrawal(owner, HUT34_WALLET, this.balance);
        HUT34_WALLET.transfer(this.balance);
        return true;
    }

    function clearKyc(address[] _addrs)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        uint len = _addrs.length;
        for(uint i; i < len; i++) {
            delete mustKyc[_addrs[i]];
            ClearedKyc(_addrs[i]);
        }
        return true;
    }

    /// @dev Releases a vested tokens back to Hut34 wallet
    function releaseVested()
        public
        returns (bool)
    {
        require(now > nextReleaseDate);
        VestingReleased(nextReleaseDate);
        nextReleaseDate = nextReleaseDate.add(VESTING_PERIOD);
        return xfer(HUT34_VEST_ADDR, HUT34_WALLET, VESTED_TOKENS / 4);
    }

    // Direct refund to caller
    function refund()
        public
        returns (bool)
    {
        address[] memory addrs;
        addrs[0] = msg.sender;
        return refundFor(addrs);
    }
    
    // Bulk refunds can be pushed from a failed ICO
    function refundFor(address[] _addrs)
        public
        preventReentry()
        returns (bool)
    {
        require(fundFailed());
        uint i;
        uint len = _addrs.length;
        uint value;
        uint tokens;
        address addr;
        
        for (i; i < len; i++) {
            addr = _addrs[i];
            value = etherContributed[addr];
            tokens = balances[addr];
    
            // Return tokens
            // transfer tokens from fund wallet
            balances[HUT34_ADDRESS] = balances[HUT34_ADDRESS].add(tokens);
            delete(balances[addr]);
            Transfer(addr, HUT34_ADDRESS, tokens);
    
            delete etherContributed[addr];
    
            Refunded(addr, value);
            if (value > 0) {
                refunded = refunded.add(value);
                addr.transfer(value);
            }
        }
        return true;
    }

//
// ERC20 additional and overloaded functions
//

    // Allows a sender to transfer tokens to an array of recipients
    function transferToMany(address[] _addrs, uint[] _amounts)
        public
        noReentry
        returns (bool)
    {
        require(_addrs.length == _amounts.length);
        uint len = _addrs.length;
        for(uint i = 0; i < len; i++) {
            xfer(msg.sender, _addrs[i], _amounts[i]);
        }
        return true;
    }
    
    // Overload to check ICO success and KYC flags.
    function xfer(address _from, address _to, uint _amount)
        internal
        noReentry
        returns (bool)
    {
        require(icoSucceeded);
        require(!mustKyc[_from]);
        super.xfer(_from, _to, _amount);
        return true;
    }

    // Overload to require ICO success
    function approve(address _spender, uint _amount)
        public
        noReentry
        returns (bool)
    {
        // ICO must be successful
        require(icoSucceeded);
        super.approve(_spender, _amount);
        return true;
    }

//
// Contract management functions
//

    /// @notice Initiate a change of owner to `_owner`
    /// @param _owner The address to which ownership is to be transfered
    function changeOwner(address _owner)
        public
        onlyOwner
        returns (bool)
    {
        ChangeOwnerTo(_owner);
        newOwner = _owner;
        return true;
    }
    
    /// @notice Finalise change of ownership to newOwner
    function acceptOwnership()
        public
        returns (bool)
    {
        require(msg.sender == newOwner);
        ChangedOwner(owner, msg.sender);
        owner = newOwner;
        delete newOwner;
        return true;
    }

    // The contract can be selfdestructed after abort and all refunds have been
    // withdrawn.
    function destroy()
        public
        noReentry
        onlyOwner
    {
        require(!__abortFuse);
        require(refunded == (etherRaised - WHOLESALE_TOKENS / RATE_WHOLESALE));
        selfdestruct(owner);
    }
    
    // Owner can salvage ERC20 tokens that may have been sent to the account
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public
        onlyOwner
        preventReentry
        returns (bool) 
    {
        require(ERC20Token(_kAddr).transfer(_to, _amount));
        return true;
    }
    
    // Calculate commission on prefunded and raised ether.
    function calcCommission()
        internal
        view
        returns(uint)
    {
        // Note There is a chance this number can be larger than the ICO raise
        // because the presale funds are being kept as fiat.
        uint totalRaise = this.balance + PRESOLD_TOKENS / RATE_WHOLESALE;
        return totalRaise.div(COMMISSION_DIV);
    }
}