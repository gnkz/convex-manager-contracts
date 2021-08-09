const hre = require("hardhat");

async function main() {
  const cvxManagerAddress = "0x36C02dA8a0983159322a80FFE9F24b1acfF8B570";
  const rewardPoolAddress = "0xCF50b810E57Ac33B91dCF525C6ddd9881B139332";

  const CvxManager = await hre.ethers.getContractFactory("ConvexManager");
  const pool = await hre.ethers.getContractAt("CvxRewardPool", rewardPoolAddress);

  const manager = await CvxManager.attach(cvxManagerAddress);

  const [signer] = await ethers.getSigners();

  const signerBalanceBeforeBuying = await ethers.provider.getBalance(signer.address);

  console.log("Signer balance before buying", signerBalanceBeforeBuying.toString());

  const balanceBeforeBuying = await pool.balanceOf(cvxManagerAddress);
  console.log("Balance before buying", balanceBeforeBuying.toString());

  await manager.buyCvxAndStake(10000 * 0.995, { value: ethers.utils.parseEther("1") });

  const signerBalanceAfterBuying = await ethers.provider.getBalance(signer.address);
  console.log("Signer balance after buying", signerBalanceAfterBuying.toString());

  const balanceBefore = await pool.balanceOf(cvxManagerAddress);
  console.log("Staked balance before withdrawing", balanceBefore.toString());

  await manager.withdrawCvx(true);

  const balanceAfter = await pool.balanceOf(cvxManagerAddress);
  console.log("Staked balance after withdrawing", balanceAfter.toString());

  await manager.stakeAllCvx();

  const balanceAfterStaking = await pool.balanceOf(cvxManagerAddress);
  console.log("Staked balance after staking", balanceAfterStaking.toString());

  await manager.liquidateAll(10000 * 0.995);

  const balanceAfterLiquidatingAll = await pool.balanceOf(cvxManagerAddress);
  console.log("Staked balance after liquidating all", balanceAfterLiquidatingAll.toString());

  const signerBalanceAfterLiquidatingALl = await ethers.provider.getBalance(signer.address);
  console.log("Signer balance after liquidating all", signerBalanceAfterLiquidatingALl.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
