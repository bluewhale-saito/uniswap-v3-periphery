// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;
pragma abicoder v2;

//  블루웨일 스테이킹 메뉴에 표시되는 풀 리스트 정보를 관리하는 유틸
interface IAquaV3StakingViewer {

    enum PoolType {
        SINGLE_POOL, KSLP, PALALP, KSLPV3, AQUAV3 //    NEW : KSLPV3 (V3풀 추가) , AQUA V3풀 추가
    }

    enum DexType {
        NONE, ASV2, ASV3
    }

    enum StakingDexType {   //  
        NONE_, ASV2_, ASV3_
    }

    enum StakingStatus {
        NONE, DEPOSIT, WITHDRAW_ONLY
    }

    enum StakingDepositType {   //  
        NONE, SINGLE, PAIR_DEPOSIT_STAKING, PAIR_DEPOSIT_ONLY, V3_DEPOSIT
    }

    //  예치, 이자 토큰 정보
    struct TokenBalance {
        address token;               //  토큰 주소
        uint256 stakedBalance;       //  클레이스왑에 스테이킹 수량, 기존 마스터쉐프 스테이킹 수량
        uint256 holdBalance;         //  0, 기존 클레이스왑 예치하고 마스터쉐프에 스테이킹 하지 않은 수량
        uint256 rewardBalance;    //  NEW : 예치한 토큰의 이자 수량
    }

    //  유저 예치 정보
    struct UserBalance {   
        uint256 poolIndex;              //  예치 인덱스
        address stakingToken;           //  LP 토큰 주소
        uint256 stakedAmount;           //  클레이스왑에 스테이킹 수량, <> 기존에는 마스터쉐프 스테이킹 수량
        uint256 holdAmount;             //  0, 단일만 지갑보유량 <> 기존에는 클레이스왑 예치하고 마스터쉐프에 스테이킹 하지 않은 수량
        TokenBalance[] tokenBalances;   //  예치 및 이자 토큰 정보
        uint256 lockupPeriod;           //  락업 날짜 
        uint256 pendingPearl;           //  PEARL의 이자 정보
        // uint256 pendingKSP;          //  NEW : KSP의 이자 정보
        uint256 rewardPerDay;           //  V2 풀에서만 사용, V3에서는 스테이킹 수량을 몰라서 0 값 
                                        //  스테이킹수량 * (86400 * (0.34 + 부스터수량) * 60 / 1000) / 총스테이크수량 | 하루 수령 가능 수량
        PoolType poolType;              //  SINGLE_POOL, KSLP, PALALP, KSLPV3 (V3풀 추가)
        uint256 tokenId;             //  NEW : V3의 경우, NFT ID 
        string title;                //  NEW : 타이틀
        int24 lower;                 // @dev The lower end of the tick range for the position
        int24 upper;                 // @dev The upper end of the tick range for the position
    }

    //  LP 스테이킹 토큰 정보
    struct BaseToken {
        address token;               // 토큰 주소
        uint256 stakingAmount;       // 풀에 스테이킹된 수량
    }

    //  에어드랍 이자 정보
    struct RewardTokenInfo { 
        uint rewardCount;
        address[] rewardTokens;
    }

    //  아쿠아 V3 LP 스테이킹 정보
    struct FarmInfo {
        uint256 poolIndex;          //  예치 인덱스
        address stakingToken;       //  LP 토큰 주소
        BaseToken[] baseTokens;     //  페어 토큰 정보  (토큰주소 및 수량)
        uint256 rewardPerDay;        //  86400 * (0.34 + 부스터수량 ) * 60 / 1000 | 현재 풀에 하루 분배되는 펄 토큰 수량 
        uint256 lockupPeriod;       //  락업 날짜 0일
        PoolType poolType;          //  SINGLE_POOL, KSLP, PALALP, KSLPV3 (V3풀 추가)
        DexType dexType;
        StakingDexType stakingDexType;
        StakingStatus stakingStatus;
        StakingDepositType stakingDepositType;
        string title;               //  NEW : 타이틀
        address[] rewardTokens;    //  에어드랍 토큰 주소
        uint256 swapFee;            // swapFee
        uint160 price;
    }

    //  클레이스왑 이자 정보
    struct PendingRewardInfo { 
        uint airdropCount;
        address[] airdropTokens;
        uint[] airdropRewards;
    }

    //  풀 정보 
    struct PoolInfo {
        address token;              //  토큰 주소
        PoolType poolType;          //  V2, V3
        uint256 allocPoint;         //  Pearl 할당량
    }

    //  풀 정보
    function farmInfos() external view returns(FarmInfo[] memory farms) ;

    //  유저의 예치 정보
    function balanceOf(address account) external view returns (UserBalance[] memory userBalances) ;
}