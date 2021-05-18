// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DeFierToken is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    using SafeMath for uint256;

    //events
    event eveSetBurnRate(uint256 burn_rate);
    event eveSetFeeRate(uint256 fee_rate);
    event eveChangeDeFierAddress(address newDefierAddress);

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public burnRate = 100;
    uint256 public feeRate = 100;
    uint256 public constant rateBase = 10000;

    //DeFier fee and mint Address
    address public deFierAddress;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `GOVERNANCE_ROLE` and
     * Mint 4'000'000 DFR tokens to the account that deploys
     * the contract.
     *
     * See {ERC20-constructor} and {_mint}.
     */
    constructor() ERC20("DeFier", "DFR") {
        deFierAddress = _msgSender();

        _mint(deFierAddress, 4000000000000000000000000);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "DeFierToken: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "DeFierToken: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev change token fee Address.
     *
     * Requirements:
     *
     * - the caller must have the `GOVERNANCE_ROLE`.
     */
    function changeDeFierAddress(address newDefierAddress) public virtual {
        require(
            hasRole(GOVERNANCE_ROLE, _msgSender()),
            "DeFierToken: must have governance role to changeDeFierAddress"
        );

        deFierAddress = newDefierAddress;

        emit eveChangeDeFierAddress(newDefierAddress);
    }

    /**
     * @dev change burn_rate
     *
     * Requirements:
     *
     * - the caller must have the `GOVERNANCE_ROLE`.
     */
    function setBurnRate(uint256 burn_rate) public virtual {
        require(
            hasRole(GOVERNANCE_ROLE, _msgSender()),
            "DeFierToken: must have governance role to setRate"
        );

        burnRate = burn_rate;

        emit eveSetBurnRate(burn_rate);
    }

    /**
     * @dev change fee_rate.
     *
     * Requirements:
     *
     * - the caller must have the `GOVERNANCE_ROLE`.
     */
    function setFeeRate(uint256 fee_rate) public virtual {
        require(
            hasRole(GOVERNANCE_ROLE, _msgSender()),
            "DeFierToken: must have governance role to setRate"
        );

        feeRate = fee_rate;

        emit eveSetFeeRate(fee_rate);
    }

    /**
     * @dev transfer tokens bypassing burn and fee.
     *
     * Requirements:
     *
     * - the caller must have the `GOVERNANCE_ROLE`.
     */
    function tranferNoFeeNoBurn(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual {
        require(
            hasRole(GOVERNANCE_ROLE, _msgSender()),
            "DeFierToken: must have governance role to tranferNoFeeNoBurn"
        );

        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Override _transfer function and add burn and fee.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override(ERC20) {
        uint256 sendAmount = amount;

        /* burn x% of Tokens on every transfer */
        uint256 burnFee = (amount.mul(burnRate)).div(rateBase);
        if (burnFee > 0) {
            _burn(sender, burnFee);
        }

        /* fee of x% on every transfer */
        uint256 defierFee = (amount.mul(feeRate)).div(rateBase);
        if (defierFee > 0) {
            super._transfer(sender, deFierAddress, defierFee);
        }

        /* send the remainder amount to the receipent */
        sendAmount = sendAmount.sub(burnFee.add(defierFee));
        super._transfer(sender, recipient, sendAmount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}