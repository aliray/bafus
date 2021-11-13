const {
    expect
} = require("chai")
const {
    ethers
} = require("hardhat")

describe("baufs testing.", function () {

    let weth10

    let bafusRouter
    let comptroller
    let baseInterestModel
    let priceOracle

    let mockErc20
    let mockBtoken

    beforeEach(async () => {

        let weth10Contract = await ethers.getContractFactory("WETH10")
        weth10 = await weth10Contract.deploy()

        let rateContract = await ethers.getContractFactory("BaseRateModel")
        baseInterestModel = await rateContract.deploy(ethers.utils.parseEther("0.425"), ethers.utils.parseEther("0.315"))
    })

    it("interest rate model", async function () {
        let rate = await baseInterestModel.getBorrowRate(
            ethers.utils.parseEther("1000"),
            ethers.utils.parseEther("500"),
            ethers.utils.parseEther("500")
        )
        console.log(rate.toNumber() / 1e18)
    })
})