// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICvxRewardPool.sol";
import "./IRouter.sol";

contract ConvexManager is Ownable {
    uint256 public constant SLIPPAGE_DENOMINATOR = 10000;

    ICvxRewardPool public cvxRewardPool;

    IRouter public router;

    IERC20 public cvx;
    IERC20 public cvxCrv;

    address public weth;

    address[] private _ethToCvxPath;
    address[] private _cvxToEthPath;
    address[] private _cvxCrvToCvxPath;

    constructor(
        address _initialCvxRewardsPoolAddress,
        address _initialCvxAddress,
        address _initialCvxCrvAddress,
        address _initialWethAddress,
        address _initialRouterAddress
    ) {
        _setCvxRewardPool(_initialCvxRewardsPoolAddress);
        _setCvx(_initialCvxAddress);
        _setCvxCrv(_initialCvxCrvAddress);
        _setRouter(_initialRouterAddress);
        _setWethAddress(_initialWethAddress);

        _setEthToCvxPath();
        _setCvxToEthPath();
        _setCvxCrvToCvxPath();

        uint256 maxInt = 2**256 - 1;

        _approveToken(_initialCvxAddress, msg.sender, maxInt);
        _approveToken(_initialCvxCrvAddress, msg.sender, maxInt);

        _approveToken(
            _initialCvxAddress,
            _initialCvxRewardsPoolAddress,
            maxInt
        );

        _approveToken(_initialCvxAddress, _initialRouterAddress, maxInt);
        _approveToken(_initialCvxCrvAddress, _initialRouterAddress, maxInt);
    }

    function buyCvx(uint256 slippage) public payable onlyOwner {
        require(msg.value > 0, "cannot buy with 0 eth.");
        require(slippage < SLIPPAGE_DENOMINATOR, "slippage > 100%.");

        uint256 minAmountOut = _calculateSwapMinAmountOut(
            msg.value,
            slippage,
            _ethToCvxPath
        );

        require(minAmountOut > 0, "zero min amount.");

        router.swapExactETHForTokens{value: msg.value}(
            minAmountOut,
            _ethToCvxPath,
            address(this),
            block.timestamp + 30 minutes
        );
    }

    function buyCvxAndStake(uint256 slippage) external payable onlyOwner {
        buyCvx(slippage);
        stakeAllCvx();
    }

    function swapRewards(uint256 slippage) public onlyOwner {
        require(slippage < SLIPPAGE_DENOMINATOR, "slippage > 100%.");

        if (earnedRewards() > 0) {
            claimCvxRewards();
        }

        uint256 amountIn = cvxCrvBalance();

        require(amountIn > 0, "zero amount in.");

        uint256 minAmountOut = _calculateSwapMinAmountOut(
            amountIn,
            slippage,
            _cvxCrvToCvxPath
        );

        require(minAmountOut > 0, "zero min amount.");

        router.swapExactTokensForTokens(
            amountIn,
            minAmountOut,
            _cvxCrvToCvxPath,
            address(this),
            block.timestamp + 30 minutes
        );
    }

    function swapRewardsAndStake(uint256 slippage) external onlyOwner {
        swapRewards(slippage);
        stakeAllCvx();
    }

    function liquidateAll(uint256 slippage) external onlyOwner {
        withdrawCvx(true);

        if (cvxCrvBalance() > 0) {
            swapRewards(slippage);
        }

        uint256 amountIn = cvxBalance();

        require(amountIn > 0, "zero amount in.");

        uint256 minAmountOut = _calculateSwapMinAmountOut(
            amountIn,
            slippage,
            _cvxToEthPath
        );

        require(minAmountOut > 0, "zero min amount out.");

        router.swapExactTokensForETH(
            amountIn,
            minAmountOut,
            _cvxToEthPath,
            msg.sender,
            block.timestamp + 30 minutes
        );
    }

    function approveCvx(address account, uint256 amount) external {
        approveToken(address(cvx), account, amount);
    }

    function approveCvxCrv(address account, uint256 amount) external {
        approveToken(address(cvxCrv), account, amount);
    }

    function approveToken(
        address token,
        address account,
        uint256 amount
    ) public onlyOwner {
        _approveToken(token, account, amount);
    }

    function claimCvxRewards() public onlyOwner {
        cvxRewardPool.getReward(false);
    }

    function withdrawCvx(bool claim) public onlyOwner {
        cvxRewardPool.withdrawAll(claim);
    }

    function stakeAllCvx() public onlyOwner {
        cvxRewardPool.stakeAll();
    }

    function earnedRewards() public view returns (uint256) {
        return cvxRewardPool.earned(address(this));
    }

    function cvxBalance() public view returns (uint256) {
        return cvx.balanceOf(address(this));
    }

    function stakedCvxBalance() public view returns (uint256) {
        return cvxRewardPool.balanceOf(address(this));
    }

    function cvxCrvBalance() public view returns (uint256) {
        return cvxCrv.balanceOf(address(this));
    }

    function setCvxRewardPool(address _newCvxRewardPoolAddress)
        external
        onlyOwner
    {
        _setCvxRewardPool(_newCvxRewardPoolAddress);
    }

    function setCvx(address _newCvxAdress) external onlyOwner {
        _setCvx(_newCvxAdress);
        _setEthToCvxPath();
        _setCvxToEthPath();
        _setCvxCrvToCvxPath();
    }

    function setCvxCrv(address _newCvxCrvAddress) external onlyOwner {
        _setCvxCrv(_newCvxCrvAddress);
        _setCvxCrvToCvxPath();
    }

    function setRouter(address _newRouterAddress) external onlyOwner {
        _setRouter(_newRouterAddress);
    }

    function setWethAddress(address _newWethAddress) external onlyOwner {
        _setWethAddress(_newWethAddress);
        _setEthToCvxPath();
        _setCvxToEthPath();
    }

    function _calculateSwapMinAmountOut(
        uint256 _amountIn,
        uint256 _slippage,
        address[] memory _path
    ) internal view returns (uint256) {
        uint256[] memory amountsOut = router.getAmountsOut(_amountIn, _path);

        uint256 amountOut = amountsOut[amountsOut.length - 1];

        return
            (amountOut * (SLIPPAGE_DENOMINATOR - _slippage)) /
            SLIPPAGE_DENOMINATOR;
    }

    function _approveToken(
        address _token,
        address _account,
        uint256 _amount
    ) internal {
        IERC20(_token).approve(_account, _amount);
    }

    function _setCvxRewardPool(address _newCvxRewardPoolAddress) internal {
        cvxRewardPool = ICvxRewardPool(_newCvxRewardPoolAddress);
    }

    function _setCvx(address _newCvxAdress) internal {
        cvx = IERC20(_newCvxAdress);
    }

    function _setCvxCrv(address _newCvxCrvAddress) internal {
        cvxCrv = IERC20(_newCvxCrvAddress);
    }

    function _setRouter(address _newRouterAddress) internal {
        router = IRouter(_newRouterAddress);
    }

    function _setWethAddress(address _newWethAddress) internal {
        weth = _newWethAddress;
    }

    function _setEthToCvxPath() internal {
        _ethToCvxPath = [weth, address(cvx)];
    }

    function _setCvxToEthPath() internal {
        _cvxToEthPath = [address(cvx), weth];
    }

    function _setCvxCrvToCvxPath() internal {
        _cvxCrvToCvxPath = [address(cvxCrv), address(cvx)];
    }
}
