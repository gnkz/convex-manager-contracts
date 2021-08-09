// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

	 function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

	function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        returns (uint[] memory amounts);
}
