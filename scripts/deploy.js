const hre = require("hardhat");

async function main() {
  const cvxRewardsPool = "0xCF50b810E57Ac33B91dCF525C6ddd9881B139332";
  const cvxToken = "0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B";
  const cvxCrvToken = "0x62b9c7356a2dc64a1969e19c23e4f579f9810aa7";
  const wethToken = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
  const sushiRouter = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F";

  const CvxManager = await hre.ethers.getContractFactory("ConvexManager");

  const cvxManager = await CvxManager.deploy(
    cvxRewardsPool,
    cvxToken,
    cvxCrvToken, 
    wethToken,
    sushiRouter,
  );

  await cvxManager.deployed();

  console.log("CvxManager deployed to:", cvxManager.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
