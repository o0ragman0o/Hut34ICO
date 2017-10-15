# Hut34ICO

Escrowing ICO/ERC20 contract for Hut34

A collated contract set for the receipt and escrowing of funds for purchase,
production and allocation of 'Entropy (ENT)' ERC20 tokens as specified by Hut34.

Web presence: 

[Hut32.io](https://hut34.io/)

[Whitepaper](https://docsend.com/view/b4h7ygu)

### Contracts

`Hut34ICOConfig` - Precompiled ICO configuration parameters.

`SafeMath` - Library to protect against mathematical overflows and underflows.

`ReentryProtected` - To explicitly protect against contract reentrancy attacks.

`ERC20Token` - Standard ERC20 token implementation

`Hut34ICOAbstract` - Constants, variables, modifiers and abstract functions
defining the Hut34ICO API in addition to inherited contract API's.

`Hut34ICO is ReentryProtected, ERC20Token, Hut34ICOAbstract, Hut34Config` - The
complete Hut34ICO contract implementation.

### Overview

The purpose of an Ethereum ICO contract is to accept funds and attribute tokens
to the funder according to some relatively calculated value. Many ICO models have
been tried in the blockchain industry which have presented diverse properties
and behaviours.

The Hut34ICO encodes an *escrowing* feature in which all funds raised are
maintained in the contract until the owner successfully calls `finalizeICO()`.
If that function is not called successfully within 7 days of the ICO's end date,
any account may call the `abort()` function which allows funders to call `refund()` and
recover their ether.

The Hut34 ICO contract also witholds and releases vested tokens according to the
whitepaper specifications.

### Features and Behaviours
* Holds fixed supply of tokens
* `HUT34_WALLET` is initiated with balance of `totalSupply`
* Accepts purchases from `START_DATE` until `END_DATE` or `icoSucceeded == true`
* Purchase by call to default function
* Purchase by call to `proxyPurchase(address)` providing an address
* Purchased tokens are transferred from `HUT34_ADDRESS` to purchaser
* Token transfers are frozen until ICO is successful
* Token wholesale rate for transaction values greater than `WHOLESALE_THRESHOLD`
* Rejects wholesale purchases if tokens would be in excess of `wholesaleLeft` 
* Time dependant Token retail rates
* Rejects retail and wholesale transactions that would reduce `HUT34_ADDRESS` balance to less than 70% of `totalSupply`
* Sets KYC flag on addresses with purchase values in excess of `KYC_THRESHOLD`
* KYC flag must be cleared by owner calling `clearKyc(address[])` before holder can transfer tokens.
* Holds funds until 'finalizeICO()' is called successfully
* 'finalizeICO()' will succeed if `etherRaised >= MIN_CAP` and `fundFailed() == true`

The following happens upon a successful call to `finalizeICO`:

* Developer commission is sent to `COMMISSION_WALLET` 
* Remaining funds are sent to `HUT34_WALLET` 
* 20% of `totalSupply` is transferred to `HUT43_VEST_ADDR` pseudo-address
* 25% of vested tokens can be released back to `HUT34_ADDRESS` once every 6 months
* `icoSucceeded == true`
* Tokens which are not KYC flagged can be transferred
* `releaseVest()` can be called by anyone every 6 months after `icoSucceeded == true`

Aborting and Refunding

* `abort()` will cause `fundFailed() == true`
* Owner can call `abort()` any time before before `finalizeICO()` returns `true`
* Anyone can call `abort()` from 7 days after `END_DATE` if `icoSucceeded == false`
* `refund()` and `refundFor(address[])` may be called by anyone if `fundFailed() == true`
* owner may call `destroy()` to `sefldestruct` the contract after `refunded == etherRaised`

#### ICO Fail conditions
`fundFailed()` will return `true` on the following conditions:

* `abort()` is called by the owner any time before `icoSucceeded` is true
* `etherRaised < MIN_CAP` at `END_DATE`
* `abort()` is called by anyone 7 days after `END_DATE`

#### ICO Success conditions
`finalizeICO()` will succeed on the conditions:

* `fundFailed()` returns false, and
* `etherRaised > MIN_CAP` prior to `END_DATE`

`finalizeICO()` can be called earlier than `END_DATE` if the `owner` decides
the funding is full or sufficient.

#### Refunding
Funders can recover their funds from a failed ICO by calling the `refund()`
function with the account they used to fund.

Additionally, anyone can call `refundFor(address[])` providing an array of
addresses to which refunds will be processed.

#### Successful Funding
`finalizeICO()` is called by the owner.  A successful finalization will transfer
the developers commision to the developers wallet, transfer the remaining to the
`HUT34_WALLET`

### Deployment

Gas requirment: < 2,000,000
Contract size: < 8kb
Constructor arguments: none. All Hut34 parameters are precompiled in `Hut34Config`.

### Parameters
The Hut34ICO contract has all parameters precompiled into the contract code.
This prevents the risk of misconfiguations which can arrise by passing arguments
to a constructor.

Parameters are:

**ERC20 Paramters**

* string name: "Hut34 Entropy Token"
* string symbol:  "ENT"
* uint TOTAL_TOKENS: 100,000,000
* uint8 decimals: TBA

**ICO Parameters**

* address OWNER: TBA
* address HUT34_ADDRESS: TBA
* address HUT34_WALLET: TBA
* uint START_DATE: 1508335200 *"00:00 19 October 2017"*
* uint END_DATE: START_DATE + 35 days (calculated in constructor)
* uint MIN_CAP: 4000 ether (to be confirmed)
* uint VESTED_PERCENT: 20%
* uint VESTING_PERIOD: 26 weeks

**Token/Ether Purchase Rates**

* uint RATE_DAY_0: 750
* uint RATE_DAY_1: 652
* uint RATE_DAY_7: 588
* uint RATE_DAY_14: 545
* uint RATE_DAY_21: 517
* uint RATE_DAY_28: 500

**KYC and Wholesale** (To discuss with Hut34)

* uint KYC_THRESHOLD = 40 ether (< $15000 USD)
* uint WHOLESALE_THRESHOLD = 150 ether
* uint WHOLESALE_TOKENS = 12,500,000 ENT
* uint RATE_WHOLESALE = 1000 ENT/ETH

### Contract Config
```
contract Hut34Config
{
    // ERC20 token name
    string  public constant name            = "Hut34 Entropy Token";
    
    // ERC20 trading symbol
    string  public constant symbol          = "ENT";

// TODO: Get decimal preference from Hut34
    // ERC20 decimal places
    uint8   public constant decimals        = 6;

    // Total supply (* in unit ENT *)
    uint    public constant TOTAL_TOKENS    = 100000000;

// TODO: uncomment and configure actual address
    // Contract owner.
    // address public constant OWNER           = 0x0;
    address public          OWNER           = msg.sender;
    
// TODO: uncomment correct date. Set as `constant`
    // + new Date("00:00 19 October 2017")/1000
    // uint    public constant START_DATE      = 1508335200;
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

// TODO: Hut34 to advise on actual wholesale rate
    // wholesale rate for purchases over WHOLESALE_THRESHOLD ether
    uint    public constant RATE_WHOLESALE  = 1000;

    /// Time dependant retail rates
    // Day 1 : October 19th 00:00 - 23:59	750	0.00133
    // + new Date("00:00 19 October 2017")/1000
    uint    public constant RATE_DAY_0      = 750;

    // Week 1 : October 20th 00:00 - October 25th 23:59	652	0.00153
    // + new Date("00:00 20 October 2017")/1000
    uint    public constant RATE_DAY_1      = 652;

    // Week 2 : October 26th 00:00 - November 1st 23:59	588	0.00170
    // + new Date("00:00 26 October 2017")/1000
    uint    public constant RATE_DAY_7      = 588;

    // Week 3 : November 2nd 00:00 - November 8th 23:59	545	0.00183
    // + new Date("00:00 2 November 2017")/1000
    uint    public constant RATE_DAY_14     = 545;

    // Week 4 : November 9th 00:00 - November 15th 23:59	517	0.00193
    // + new Date("00:00 9 November 2017")/1000
    uint    public constant RATE_DAY_21     = 517;

    // Week 5 : November 16th 00:00 - November 21st 23:59	500	0.002
    // + new Date("00:00 16 November 2017")/1000
    uint    public constant RATE_DAY_28     = 500;
}

```
### Hut34ICOAbstract
```
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
```
