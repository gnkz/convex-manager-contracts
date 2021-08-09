const hre = require("hardhat");

async function main() {
  const CvxManager = await hre.ethers.getContractFactory("ConvexManager");
  const cvxManagerAddress = "0x36c02da8a0983159322a80ffe9f24b1acff8b570";

  const manager = await CvxManager.attach(cvxManagerAddress);

  const test = await manager.buyCvxAndStake(10000 * 0.995, { value: ethers.utils.parseEther("1") });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
