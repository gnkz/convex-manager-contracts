// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICvxRewardPool {
    function balanceOf(address account) external view returns (uint256);

    function stakeAll() external;

    function withdrawAll(bool claim) external;

    function getReward(bool _stake) external;

    function earned(address account) external view returns (uint256);
}
