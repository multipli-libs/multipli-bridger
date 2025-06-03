// SPDX-License-Identifier: MIT

pragma solidity 0.8.29;
import {Initializable, ContextUpgradeable} from "./Initializable.sol";
import "./TransferHelper.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        require(_owner != newOwner, "Ownable: new owner is the same as current owner");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

/**
 * Brine bridger for cross-chain interoperability
 */
contract MultipliBridger is OwnableUpgradeable {
    mapping(address => bool) public authorized;
    mapping(string => bool) public processedWithdrawalIds;
    mapping(address => bool) public registeredTokens;
    
    event TokenRegistered(address indexed token, address indexed by);
    event TokenDeregistered(address indexed token, address indexed by);
    event BridgedDeposit(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event BridgedWithdrawal(
        address indexed user,
        address indexed token,
        uint256 amount,
        string withdrawalId
    );

    modifier _isAuthorized() {
        require(authorized[msg.sender], "UNAUTHORIZED");
        _;
    }

    modifier _validateWithdrawalId(string calldata withdrawalId) {
        require(bytes(withdrawalId).length > 0, "Withdrawal ID is required");
        require(
            !processedWithdrawalIds[withdrawalId],
            "Withdrawal ID Already processed"
        );
        _;
    }
    
    modifier _isRegisteredToken(address token) {
        require(registeredTokens[token], "Token is not registered");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        authorized[_msgSender()] = true;
    }

    /**
     * @dev Register a token that can be used for deposits
     * NOTE: only owner or authorized users can register tokens
     */
    function registerToken(address token) external _isAuthorized {
        require(token != address(0), "Cannot register zero address as token");
        require(!registeredTokens[token], "Token already registered");
        
        registeredTokens[token] = true;
        
        emit TokenRegistered(token, msg.sender);
    }
    
    /**
     * @dev Unregister a token
     * NOTE: only owner or authorized users can unregister tokens
     */
    function deregisterToken(address token) external _isAuthorized {
        require(registeredTokens[token], "Token not registered");
        
        registeredTokens[token] = false;
        
        emit TokenDeregistered(token, msg.sender);
    }

    /**
     * @dev Deposit ERC20 tokens into the contract address, must be approved
     * NOTE: token must be registered
     */
    function deposit(address token, uint256 amount) external _isRegisteredToken(token) {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
        emit BridgedDeposit(msg.sender, token, amount);
    }

    /**
     * @dev Deposit native chain currency into contract address
     */
    function depositNative() external payable {
        emit BridgedDeposit(msg.sender, address(0), msg.value); // Maybe create new events for ETH deposit/withdraw
    }

    /**
     * @dev Deposit ERC20 token into the contract address
     * NOTE: Restricted deposit function for rebalancing
     */
    function addFunds(address token, uint256 amount) external _isAuthorized {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @dev Deposit native chain currency into the contract address
     * NOTE: Restricted deposit function for rebalancing
     */
    function addFundsNative() external payable _isAuthorized {}

    /**
     * @dev withdraw ERC20 tokens from the contract address
     * NOTE: only for authorized users
     */
    function withdraw(
        address token,
        address to,
        uint256 amount,
        string calldata withdrawalId
    ) external _isAuthorized _validateWithdrawalId(withdrawalId) {
        processedWithdrawalIds[withdrawalId] = true;
        TransferHelper.safeTransfer(token, to, amount);
        emit BridgedWithdrawal(to, token, amount, withdrawalId);
    }

    /**
     * @dev withdraw native chain currency from the contract address
     * NOTE: only for authorized users
     */
    function withdrawNative(
        address payable to,
        uint256 amount,
        string calldata withdrawalId
    ) external _isAuthorized _validateWithdrawalId(withdrawalId) {
        processedWithdrawalIds[withdrawalId] = true;
        removeFundsNative(to, amount);
        emit BridgedWithdrawal(to, address(0), amount, withdrawalId);
    }

    /**
     * @dev withdraw ERC20 token from the contract address
     * NOTE: only for authorized users for rebalancing
     */
    function removeFunds(
        address token,
        address to,
        uint256 amount
    ) external _isAuthorized {
        TransferHelper.safeTransfer(token, to, amount);
    }

    /**
     * @dev withdraw native chain currency from the contract address
     * NOTE: only for authorized users for rebalancing
     */
    function removeFundsNative(
        address payable to,
        uint256 amount
    ) public _isAuthorized {
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");
        (bool success, ) = to.call{value: amount}("");
        require(success, "TRANSFER_FAILED");
    }

    /**
     * @dev add or remove authorized users
     * NOTE: only owner
     */
    function authorize(address user, bool value) external onlyOwner {
        require(user != address(0), "Authorization: user cannot be zero address");
        require(authorized[user] != value, "Authorization: user already has this authorization status");
        authorized[user] = value;
    }

    function transferOwner(address newOwner) external onlyOwner {
        authorized[newOwner] = true;
        authorized[owner()] = false;
        transferOwnership(newOwner);
    }

    function renounceOwnership() public view override onlyOwner {
        require(false, "Unable to renounce ownership");
    }
}