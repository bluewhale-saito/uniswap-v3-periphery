// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import './interfaces/IAquaV3StakingViewer.sol';
import './interfaces/IUniswapV3Factory.sol';

/**
 * @dev ERC20 표준의 선택적 인터페이스로 name, symbol, decimals 정보를 포함합니다.
 */
interface IERC20Metadata {
    /**
     * @dev 토큰의 이름을 리턴합니다 (예: "Wrapped AVAX").
     */
    function name() external view returns (string memory);

    /**
     * @dev 토큰의 심볼을 리턴합니다 (예: "WAVAX").
     */
    function symbol() external view returns (string memory);

    /**
     * @dev 토큰의 소수점 자릿수를 리턴합니다 (보통 18).
     */
    function decimals() external view returns (uint8);
}

//  아쿠아스페이스 스테이킹 메뉴에 표시되는 풀 리스트 정보 추출 (V3 풀정보)
//  풀에 예치하고있는 정보를 추출
contract AquaV3StakingViewer is IAquaV3StakingViewer {

    // Uniswap V3 공식 주소 (메인넷 기준 예시)
    address public constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    
    address public constant AVAX = address(0);
    address public WAVAX = address(0xAB4fBa02a2905a03adA8BD3d493FB289Dcf84024);
  
    function farmInfos() public view override returns(IAquaV3StakingViewer.FarmInfo[] memory farms) {

        uint256 poolLength = IUniswapV3Factory(FACTORY).allPoolsLength();
        farms = new IAquaV3StakingViewer.FarmInfo[](poolLength);
        uint256 size;

        for(uint256 i=0; i<poolLength; i++) {
            address lpToken = IUniswapV3Factory(FACTORY).allPools(i);

            IAquaV3StakingViewer.BaseToken[] memory baseTokens;

            //  판게아 스왑
            IUniswapV3Pool pool = IUniswapV3Pool(lpToken);

            baseTokens = new IAquaV3StakingViewer.BaseToken[](2);
            baseTokens[0] = IAquaV3StakingViewer.BaseToken({
                token: checkWAVAX(pool.token0()),
                stakingAmount: IERC20(pool.token0()).balanceOf(lpToken)
            });

            baseTokens[1] = IAquaV3StakingViewer.BaseToken({
                token: checkWAVAX(pool.token1()),
                stakingAmount: IERC20(pool.token1()).balanceOf(lpToken)
            });

            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

            farms[size] = IAquaV3StakingViewer.FarmInfo({
                poolIndex: i,
                stakingToken: lpToken,
                baseTokens: baseTokens,
                rewardPerDay: 0,
                lockupPeriod: 0,
                poolType: IAquaV3StakingViewer.PoolType.AQUAV3,
                dexType: IAquaV3StakingViewer.DexType.ASV3,
                stakingDexType: IAquaV3StakingViewer.StakingDexType.ASV3_,
                stakingStatus: IAquaV3StakingViewer.StakingStatus.DEPOSIT,
                stakingDepositType: IAquaV3StakingViewer.StakingDepositType.V3_DEPOSIT,
                title: getTitle(pool.token0(), pool.token1()),
                rewardTokens: new address[](0),
                swapFee: uint256(pool.fee()),   // uint24를 uint256으로 변환
                price: sqrtPriceX96    // sqrtPriceX96 값을 전달
            });
            size++;
        }
    }

    // 특정 풀 조회 추가
    function farmInfo(address poolAddr) public view returns(IAquaV3StakingViewer.FarmInfo memory farm) {
    
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);

        address token0 = pool.token0();
        address token1 = pool.token1();
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        IAquaV3StakingViewer.BaseToken[] memory baseTokens = new IAquaV3StakingViewer.BaseToken[](2);
        baseTokens[0] = IAquaV3StakingViewer.BaseToken({
            token: token0,
            stakingAmount: IERC20(token0).balanceOf(poolAddr)
        });
        baseTokens[1] = IAquaV3StakingViewer.BaseToken({
            token: token1,
            stakingAmount: IERC20(token1).balanceOf(poolAddr)
        });

        farm = IAquaV3StakingViewer.FarmInfo({
            poolIndex: 0,
            stakingToken: poolAddr,
            baseTokens: baseTokens,
            rewardPerDay: 0,
            lockupPeriod: 0,
            poolType: IAquaV3StakingViewer.PoolType.AQUAV3,
            dexType: IAquaV3StakingViewer.DexType.ASV3,
            stakingDexType: IAquaV3StakingViewer.StakingDexType.ASV3_,
            stakingStatus: IAquaV3StakingViewer.StakingStatus.DEPOSIT,
            stakingDepositType: IAquaV3StakingViewer.StakingDepositType.V3_DEPOSIT,
            title: getTitle(pool.token0(), pool.token1()),
            rewardTokens: new address[](0),
            swapFee: uint256(pool.fee()),   // uint24를 uint256으로 변환
            price: sqrtPriceX96    // sqrtPriceX96 값을 전달
        });        
    }

    function getPoolIndex(address lpAddress) public view returns(uint256 index) {
        uint256 poolLength = IUniswapV3Factory(FACTORY).allPoolsLength();
        for(uint256 i=0; i<poolLength; i++) {
            address lpToken = IUniswapV3Factory(FACTORY).allPools(i);
            if(lpToken == lpAddress){
                index = i;
                break;
            }
        }
    }


    function balanceOf(address account) public view override returns (UserBalance[] memory userBalances) {

        INonfungiblePositionManager npm = INonfungiblePositionManager(POSITION_MANAGER);
        uint256 balanceLength = npm.balanceOf(account);
        
        userBalances = new UserBalance[](balanceLength);

        uint256 size;

        for(uint256 i = 0; i < balanceLength; i++) {
            uint256 tokenId = npm.tokenOfOwnerByIndex(account, i);

            // 총 12개의 리턴값 중 필요한 것만 추출 (콤마 위치 주의)
            (
                , // 1. nonce
                , // 2. operator
                address token0, // 3. token0
                address token1, // 4. token1
                uint24 fee,     // 5. fee
                int24 tickLower, // 6. tickLower
                int24 tickUpper, // 7. tickUpper
                uint128 liquidity, // 8. liquidity
                , // 9. feeGrowthInside0LastX128
                , // 10. feeGrowthInside1LastX128
                , // 11. tokensOwed0
                // 12. tokensOwed1 (마지막 값 뒤에는 콤마가 붙지 않습니다)
            ) = npm.positions(tokenId);

            address poolAddr = IUniswapV3Factory(FACTORY).getPool(token0, token1, fee);
            
            // 수수료 및 예치량 계산 로직 (간소화)
            TokenBalance[] memory tokenBalances = new TokenBalance[](2);
            // 주의: 유니V3는 현재 틱에 따라 amount0, 1이 실시간으로 변함 (LiquidityAmounts 라이브러리 필요)

            userBalances[i] = UserBalance({
                poolIndex: i,
                stakingToken: poolAddr,
                stakedAmount: uint256(liquidity),
                holdAmount: 0,
                tokenBalances: tokenBalances,
                pendingPearl: 0,
                rewardPerDay: 0,
                lockupPeriod: 0,
                poolType: IAquaV3StakingViewer.PoolType.AQUAV3,
                tokenId: tokenId,
                title: getTitle(token0, token1),
                lower: tickLower,
                upper: tickUpper
            });

            size++;
        }

        uint256 shrink = userBalances.length - size;
        if(shrink > 0)
            assembly { mstore(userBalances, sub(mload(userBalances), shrink)) }
    }

    // 특정 positionId 조회 추가
    // function balanceOfByPositionId(uint256 positionId) public view returns (UserBalance memory userBalance) {
     
    //     IConcentratedLiquidityPoolManager.Position memory position = customPoolManager.positions(positionId);

    //     address lpToken = position.pool;
    //     TokenBalance[] memory tokenBalances = initializeTokenBalance(lpToken, positionId);

    //     userBalance = createUserBalance(
    //         getPoolIndex(lpToken),
    //         lpToken,
    //         position,
    //         // position.liquidity, // stakedAmount, 
    //         // 0, // holdAmount, 
    //         tokenBalances,
    //         // 0, // pendingPearl, 
    //         // 0, // rewardPerDay, 
    //         // 0, // lockupPeriod, 
    //         PoolType.AQUAV3,
    //         positionId
    //         // getTitle(pangeaPair.token0(), pangeaPair.token1())
    //     );
    // }

     //  WAVAX 체크
    function checkWAVAX(address token) public view returns (address) {
        return token==WAVAX?AVAX:token;
    }

    //  타이틀 
    function getTitle(address token0, address token1) public view returns (string memory) {
        string memory title = string(abi.encodePacked(token0==WAVAX?"AVAX":IERC20Metadata(token0).symbol()," + ",token1==WAVAX?"AVAX":IERC20Metadata(token1).symbol()));
        return title;
    }

    //  UserBalance Stack too deep 문제로 별도 작성
    // function createUserBalance(
    //     uint256 index,
    //     address lpToken,
    //     IConcentratedLiquidityPoolManager.Position memory position,
    //     // uint256 stakedAmount,
    //     // uint256 holdAmount,
    //     TokenBalance[] memory tokenBalances,
    //     // uint256 pendingPearl,
    //     // uint256 rewardPerDay,
    //     // uint256 lockupPeriod,
    //     PoolType poolType,
    //     uint256 tokenId
    //     // string memory title
    // ) internal view returns (UserBalance memory) {
    //     IPangeaPair pangeaPair = IPangeaPair(lpToken);
    //     string memory title = getTitle(pangeaPair.token0(), pangeaPair.token1());
    //     (, uint256 rewardPerDay) = airdrop.getRewardInfoByPosition(lpToken, tokenId);

    //     return UserBalance({
    //         poolIndex: index,
    //         stakingToken: lpToken,
    //         stakedAmount: position.liquidity,
    //         holdAmount: 0,
    //         tokenBalances: tokenBalances,
    //         pendingPearl: 0,
    //         rewardPerDay: rewardPerDay,
    //         lockupPeriod: 0,
    //         poolType: poolType,
    //         tokenId: tokenId,
    //         title: title,
    //         upper: position.upper,
    //         lower: position.lower
    //     });
    // }
}


// v3 테스트용 컨트랙트
// | contract                                        | address                                      |
// |-------------------------------------------------|----------------------------------------------|
// | AirdropDistributor                              | 0xe8288DCe84753cB1b3D30A70784CE69398f7950a | 
// | MasterDeployer                                  | 0x83FFf759B326Df55958487524A4fa2AE66021A73 |
// | PoolLogger                                      | 0x7023bef156d67c7415a0c8627cD05F06f377F0D6 | 
// | PoolRouter                                      | 0x6CA89f221C5D036B8e15694e3604DA1fdDcb9Fcf |  
// | PositionDashboard                               | 0x0cdBd0289aDeeD201740C537621B888966544695 |
// | SafeSwapHelper                                  | 0x03BE74B99EA3bF40e8f4EcE8A95B771a7cf92F39 | 
// | WETH10                                          | 0x16D91B0150D4a02DCAFe304e3DaAdd8Ee0947BF4 |
// | MiningPoolFactory (custom pool)                 | 0x56D6Cd6a0aEF9B2B50316bed676bcCBEB82128dD |
// | MiningPoolManager                               | 0x2B07718E61090243153A2EB6C1373C36C9F95ac0 |
// | ClaimAggregator                                 | 0xB71a01F344177590A36Df3f9e072124eCB1e1f91 |