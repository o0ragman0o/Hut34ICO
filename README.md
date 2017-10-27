# Hut34ICO

Escrowing ICO/ERC20 contract for Hut34

A collated contract set for the receipt and escrowing of funds for production,
purchase, and allocation of 'Entropy (ENT)' ERC20 tokens as specified by Hut34.

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
to the funder according to some relatively calculated value in a trusted manner.

The Hut34ICO follows a prefunding round with prefunds and pre-sold tokens being
published in the contract and used in calculations of minium cap required.

The Hut34ICO encodes an *escrowing* feature in which all funds raised in the ICO
round are maintained in the contract until the owner successfully calls
`finalizeICO()`. If that function is not called successfully within 14 days of
the ICO's end date, any account may call the `abort()` function which allows
funders to call `refund()` and recover their ether by calling `refund()`.

All purchsed token transfers are blocked until the ICO is finalized.

The Hut34 ICO contract witholds and releases vested tokens according to the
whitepaper specifications.

### Features and Behaviours

* Holds a fixed supply of 100,000,000 tokens
* 20% of tokens are transferred to `HUT43_VEST_ADDR` vesting pseudo-address
* Vested tokens are released back to Hut34 address every 6 months for two years
* `HUT34_ADDRESS` is initiated with balance of `totalSupply`
* Accepts purchases from `START_DATE` until `END_DATE` or `icoSucceeded == true` or Hut34 tokens are at 50% of supply
* Purchase by call to default function
* Purchase by call to `proxyPurchase(address)` providing an address
* Purchased tokens are transferred from `HUT34_ADDRESS` to purchaser address
* Purchased token transfers are frozen until ICO is successful
* Time dependant Token retail rates
* Token wholesale rate calculated for transaction values greater than `WHOLESALE_THRESHOLD`
* Wholesale purchases exceeding `wholesaleLeft` are partially or totally calculated at retail rate 
* Rejects transactions that would reduce `HUT34_ADDRESS` balance to less than 50% of `totalSupply`
* Sets KYC flag on addresses with purchase values in excess of `KYC_THRESHOLD`
* KYC flag must be cleared by owner calling `clearKyc(address[])` before holder can transfer tokens.
* Holds funds until 'finalizeICO()' is called successfully
* 'finalizeICO()' will succeed if `etherRaised >= MIN_CAP` and `fundFailed() == true`

The following happens upon a successful call to `finalizeICO`:

* Developer commission is sent to `COMMISSION_WALLET` 
* Remaining funds are sent to `HUT34_WALLET` 
* `icoSucceeded == true`
* The vesting release date is set to now + 6 months
* Tokens which are not KYC flagged can be transferred
* Hut34 must clear KYC flags for KYC'ed addresses after documents have been provided
* `releaseVest()` can be called by anyone every 6 months after `icoSucceeded == true`

Aborting and Refunding

* `abort()` will cause `fundFailed() == true`
* Owner can call `abort()` any time before before `finalizeICO()` returns `true`
* Anyone can call `abort()` from 14 days after `END_DATE` if `icoSucceeded == false`
* `refund()` and `refundFor(address[])` may be called by anyone if `fundFailed() == true`
* owner may call `destroy()` to `sefldestruct` the contract after `refunded == etherRaised`

#### ICO Fail conditions
`fundFailed()` will return `true` on the following conditions:

* `abort()` is called by the owner any time before `icoSucceeded` is true
* `etherRaised < MIN_CAP` after `END_DATE`
* `abort()` is called by anyone 14 days after `END_DATE`

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

Gas requirment: <  2300000
Contract size: < 9kb
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
* uint8 decimals: 18

**ICO Parameters**

* `address OWNER: 0xdA3780Cff2aE3a59ae16eC1734DEec77a7fd8db2`
* `address HUT34_ADDRESS: 0x048Fcbf47a382fB26ADdF6e0Cb7B163D540e2E36`
* `address HUT34_RETAIN: 0x3135F4acA3C1Ad4758981500f8dB20EbDc5A1caB`
* `address PRESOLD_ADDRESS: 0x6BF708eF2C1FDce3603c04CE9547AA6E134093b6`
* `address HUT34_VEST_ADDR: 0x48757433342056657374696e6700000000000000`
    NB: Is a pseudo-address cast from the string "Hut34 Vesting"

* `uint START_DATE: 1509580800` (00:00 2 November 2017 UTC)
* `uint END_DATE: START_DATE + 35 days` (calculated in constructor)
* `uint MIN_CAP: 3000 ether`
* `uint VESTED_PERCENT: 20%`
* `uint VESTING_PERIOD: 26 weeks`
* `uint PRESOLD_TOKENS: 1817500`
* `uint PRESALE_ETH_RAISE: 2190 ether`

**Token/Ether Purchase Rates**

* `uint RATE_DAY_0: 750`
* `uint RATE_DAY_1: 652`
* `uint RATE_DAY_7: 588`
* `uint RATE_DAY_14: 545`
* `uint RATE_DAY_21: 517`
* `uint RATE_DAY_28: 500`

**KYC and Wholesale** (To discuss with Hut34)

* `uint KYC_THRESHOLD = 150 ether`
* `uint WHOLESALE_THRESHOLD = 150 ether`
* `uint WHOLESALE_TOKENS = 12,500,000 ENT`
* `uint RATE_WHOLESALE = 1000 ENT/ETH`

### Contract Config
```
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

    // Contract owner at time of deployment.
    address public constant OWNER           = 0xdA3780Cff2aE3a59ae16eC1734DEec77a7fd8db2;

    // + new Date("00:00 2 November 2017 utc")/1000
    uint    public constant START_DATE      = 1509580800;

    // A Hut34 address to own tokens
    address public constant HUT34_RETAIN    = 0x3135F4acA3C1Ad4758981500f8dB20EbDc5A1caB;
    
    // A Hut34 address to accept raised funds
    address public constant HUT34_WALLET    = 0xA70d04dC4a64960c40CD2ED2CDE36D76CA4EDFaB;
    
    // Percentage of tokens to be vested over 2 years. 20%
    uint    public constant VESTED_PERCENT  = 20;

    // Vesting period
    uint    public constant VESTING_PERIOD  = 26 weeks;

    // Minimum cap over which the funding is considered successful
    uint    public constant MIN_CAP         = 3000 * 1 ether;

    // An ether threshold over which a funder must KYC before tokens can be
    // transferred (unit of ether);
    uint    public constant KYC_THRESHOLD   = 150 * 1 ether;

    // A minimum amount of ether funding before the concierge rate is applied
    // to tokens
    uint    public constant WHOLESALE_THRESHOLD  = 150 * 1 ether;
    
    // Number of tokens up for wholesale purchasers (* in unit ENT *)
    uint    public constant WHOLESALE_TOKENS = 12500000;

    // Tokens sold to prefunders (* in unit ENT *)
    uint    public constant PRESOLD_TOKENS  = 1817500;
    
    // Presale ether is estimateed from fiat raised prior to ICO at the ETH/AUD
    // rate at the time of contract deployment
    uint    public constant PRESALE_ETH_RAISE = 2190 * 1 ether;
    
    // Address holding presold tokens to be distributed after ICO
    address public constant PRESOLD_ADDRESS = 0x6BF708eF2C1FDce3603c04CE9547AA6E134093b6;
    
    // wholesale rate for purchases over WHOLESALE_THRESHOLD ether
    uint    public constant RATE_WHOLESALE  = 1000;

    // Time dependant retail rates
    // First Day
    uint    public constant RATE_DAY_0      = 750;

    // First Week (The six days after first day)
    uint    public constant RATE_DAY_1      = 652;

    // Second Week
    uint    public constant RATE_DAY_7      = 588;

    // Third Week
    uint    public constant RATE_DAY_14     = 545;

    // Fourth Week
    uint    public constant RATE_DAY_21     = 517;

    // Fifth Week
    uint    public constant RATE_DAY_28     = 500;
}
```
### Hut34ICOAbstract

## Conditional Entry Table

Functions must throw on F conditions

Renetry prevention is on all public mutating functions
Reentry mutex set in finalizeICO(), externalXfer(), refund()

|function                |<startDate |<endDate  |fundFailed  |fundRaised|icoSucceeded
|------------------------|:---------:|:--------:|:----------:|:--------:|:---------:|
|()                      |F          |T         |F           |T         |F          |
|abort()                 |T          |T         |T           |T         |F          |
|proxyPurchase()         |F          |T         |F           |T         |F          |
|finalizeICO()           |F          |F         |F           |T         |T          |
|refund()                |F          |F         |T           |F         |F          |
|transfer()              |F          |F         |F           |F         |T          |
|transferFrom()          |F          |F         |F           |F         |T          |
|transferToMany()        |F          |F         |F           |F         |T          |
|approve()               |F          |F         |F           |F         |T          |
|clearKyc()              |T          |T         |T           |T         |T          |
|releaseVested()         |F          |F         |F           |F         |now>release|
|changeOwner()           |T          |T         |T           |T         |T          |
|acceptOwnership()       |T          |T         |T           |T         |T          |
|transferExternalTokens()|T          |T         |T           |T         |T          |
|destroy()               |F          |F         |!__abortFuse|F         |F          |

\*----------------------------------------------------------------------------*/
```
contract Hut34ICOAbstract
{
    /// @dev Logged upon receiving a deposit
    /// @param _from The address from which value has been recieved
    /// @param _value The value of ether received
    event Deposit(address indexed _from, uint _value);
    
    /// @dev Logged upon a withdrawal
    /// @param _from the address of the withdrawer
    /// @param _to Address to which value was sent
    /// @param _value The value in ether which was withdrawn
    event Withdrawal(address indexed _from, address indexed _to, uint _value);

    /// @dev Logged when new owner accepts ownership
    /// @param _from the old owner address
    /// @param _to the new owner address
    event ChangedOwner(address indexed _from, address indexed _to);
    
    /// @dev Logged when owner initiates a change of ownership
    /// @param _to the new owner address
    event ChangeOwnerTo(address indexed _to);
    
    /// @dev Logged when a funder exceeds the KYC limit
    /// @param _addr Address to set or clear KYC flag
    /// @param _kyc A boolean flag
    event Kyc(address indexed _addr, bool _kyc);

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
    // `0x48757433342056657374696e6700000000000000`
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
    /// @dev Requires 150,000 gas
    function proxyPurchase(address _addr) public payable returns (bool);

    /// @notice Finalize the ICO and transfer funds
    /// @return Boolean success value
    function finalizeICO() public returns (bool);

    /// @notice Clear the KYC flags for an array of addresses to allow tokens
    /// transfers
    function clearKyc(address[] _addrs) public returns (bool);
    
    /// @notice Make bulk transfer of tokens to many addresses
    /// @param _addrs An array of recipient addresses
    /// @param _amounts An array of amounts to transfer to respective addresses
    /// @return Boolean success value
    function transferToMany(address[] _addrs, uint[] _amounts)
        public returns (bool);

    /// @notice Release vested tokens after a maturity date
    /// @return Boolean success value
    function releaseVested() public returns (bool);

    /// @notice Claim refund on failed ICO
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