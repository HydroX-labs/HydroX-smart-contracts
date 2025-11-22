# 멀티 에셋 포지션 설계 - 단일 스테이블 코인 풀

## 🎯 핵심 컨셉

**하나의 스테이블 코인 유동성 풀**에서 **여러 자산(BTC, ETH, ADA 등)에 대한 포지션**을 거래할 수 있습니다.

이것이 바로 **GMX v1의 핵심 혁신**입니다!

## 📊 구조 설명

### 단일 유동성 풀 (USDC)

```
┌────────────────────────────────────────┐
│      Vault (USDC Pool)                 │
│                                        │
│  Total Liquidity: 1,000,000 USDC      │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  BTC Positions                   │ │
│  │  - Long:  10,000 USD (100 USDC)  │ │
│  │  - Short: 5,000 USD (50 USDC)    │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  ETH Positions                   │ │
│  │  - Long:  8,000 USD (80 USDC)    │ │
│  │  - Short: 12,000 USD (120 USDC)  │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  ADA Positions                   │ │
│  │  - Long:  3,000 USD (30 USDC)    │ │
│  │  - Short: 2,000 USD (20 USDC)    │ │
│  └──────────────────────────────────┘ │
│                                        │
│  Total Reserved: 400 USDC             │
│  Available: 999,600 USDC              │
└────────────────────────────────────────┘
```

### VaultDatum 구조

```aiken
VaultDatum {
  stablecoin: USDC,               // 단일 스테이블 코인
  total_liquidity: 1_000_000,     // 전체 USDC
  
  // 토큰별 추적 (BTC, ETH, ADA 등)
  reserved_amounts: [
    (BTC, 150),   // BTC 포지션에 예약된 USDC
    (ETH, 200),   // ETH 포지션에 예약된 USDC
    (ADA, 50),    // ADA 포지션에 예약된 USDC
  ],
  
  open_interest_long: [
    (BTC, 10_000),  // BTC 롱 포지션 총 크기
    (ETH, 8_000),   // ETH 롱 포지션 총 크기
    (ADA, 3_000),   // ADA 롱 포지션 총 크기
  ],
  
  open_interest_short: [
    (BTC, 5_000),   // BTC 숏 포지션 총 크기
    (ETH, 12_000),  // ETH 숏 포지션 총 크기
    (ADA, 2_000),   // ADA 숏 포지션 총 크기
  ],
  
  guaranteed_usd: [
    (BTC, 5_000),   // BTC 숏 포지션 보증금
    (ETH, 12_000),  // ETH 숏 포지션 보증금
    (ADA, 2_000),   // ADA 숏 포지션 보증금
  ],
  
  // 토큰별 펀딩 비율
  cumulative_funding_rate_long: [
    (BTC, 1500),
    (ETH, 2000),
    (ADA, 500),
  ],
  
  cumulative_funding_rate_short: [
    (BTC, -1500),
    (ETH, -2000),
    (ADA, -500),
  ],
  
  // 화이트리스트 (거래 가능한 토큰)
  whitelisted_tokens: [BTC, ETH, ADA, SOL, ...],
  
  // 토큰별 최대 사용률 (80% = 8000 basis points)
  max_utilization: [
    (BTC, 8000),   // BTC는 최대 80%까지
    (ETH, 8000),   // ETH는 최대 80%까지
    (ADA, 7000),   // ADA는 최대 70%까지 (더 위험)
  ],
}
```

### Position 구조

```aiken
// User A: BTC 롱 포지션
Position {
  owner: "user_a_pkh",
  index_token: BTC,          // BTC 가격 추적
  position_type: Long,
  size: 10_000,              // 10,000 USD 포지션
  collateral: 1_000,         // 1,000 USDC 담보
  average_price: 40_000,     // BTC @ 40,000 USD
  entry_funding_rate: 1200,  // BTC 롱 진입 시 펀딩
}

// User B: ETH 숏 포지션
Position {
  owner: "user_b_pkh",
  index_token: ETH,          // ETH 가격 추적
  position_type: Short,
  size: 5_000,               // 5,000 USD 포지션
  collateral: 500,           // 500 USDC 담보
  average_price: 2_500,      // ETH @ 2,500 USD
  entry_funding_rate: -1800, // ETH 숏 진입 시 펀딩
}

// User C: ADA 롱 포지션
Position {
  owner: "user_c_pkh",
  index_token: ADA,          // ADA 가격 추적
  position_type: Long,
  size: 1_000,               // 1,000 USD 포지션
  collateral: 100,           // 100 USDC 담보
  average_price: 0.5,        // ADA @ 0.5 USD
  entry_funding_rate: 300,   // ADA 롱 진입 시 펀딩
}
```

## 🔄 실제 플로우 예시

### 시나리오 1: BTC 롱 포지션 오픈

```typescript
// 사용자가 BTC 롱 10x 레버리지로 포지션 오픈
// 담보: 1,000 USDC
// 포지션 크기: 10,000 USD

// 1. Vault 상태 업데이트
VaultDatum (Before):
  total_liquidity: 100,000 USDC
  reserved_amounts: [(BTC, 0)]
  open_interest_long: [(BTC, 0)]

VaultDatum (After):
  total_liquidity: 100,000 + 30 USDC (마진 수수료 0.3%)
  reserved_amounts: [(BTC, 1,000)]        // 1,000 USDC 예약
  open_interest_long: [(BTC, 10,000)]     // 10,000 USD 롱

// 2. Position UTXO 생성
Position {
  owner: user_pkh,
  index_token: BTC,
  size: 10,000,
  collateral: 1,000,
  average_price: 40,000,  // 현재 BTC 가격
}
```

### 시나리오 2: ETH 숏 포지션 오픈 (동시에!)

```typescript
// 다른 사용자가 동시에 ETH 숏 5x 레버리지
// 담보: 500 USDC
// 포지션 크기: 2,500 USD

// Vault 상태 업데이트 (BTC와 별개!)
VaultDatum:
  total_liquidity: 100,030 + 7.5 USDC (수수료)
  reserved_amounts: [
    (BTC, 1,000),  // BTC는 그대로
    (ETH, 500),    // ETH 추가!
  ]
  open_interest_short: [(ETH, 2,500)]     // ETH 숏
  guaranteed_usd: [(ETH, 2,500)]          // 숏 보증금

// Position UTXO 생성
Position {
  owner: user2_pkh,
  index_token: ETH,
  position_type: Short,
  size: 2,500,
  collateral: 500,
  average_price: 2,500,  // 현재 ETH 가격
}
```

## 🎯 왜 이 구조가 강력한가?

### 1. 자본 효율성

```
전통적 방식 (분리된 풀):
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  BTC Pool    │  │  ETH Pool    │  │  ADA Pool    │
│  100,000 USD │  │  100,000 USD │  │  100,000 USD │
└──────────────┘  └──────────────┘  └──────────────┘
Total: 300,000 USD (분산됨)

GMX 방식 (단일 풀):
┌──────────────────────────────────────────────┐
│         Single USDC Pool                     │
│         300,000 USD                          │
│  (BTC, ETH, ADA 모두 이 풀 사용)            │
└──────────────────────────────────────────────┘
Total: 300,000 USD (효율적!)
```

**장점:**
- 유동성이 한 곳에 집중 → 더 큰 포지션 가능
- 한 토큰에 수요 없어도 다른 토큰으로 수익
- LP는 여러 토큰에 분산 투자 효과

### 2. 위험 분산

```
시나리오: BTC가 폭락

분리된 풀:
  BTC Pool: 큰 손실 💥
  ETH Pool: 영향 없음
  ADA Pool: 영향 없음

단일 풀 (GMX):
  전체 풀: BTC 손실 + ETH/ADA 수익으로 상쇄 가능 ✅
```

### 3. 펀딩 비율 (토큰별)

```
BTC:
  Long: 10,000 USD
  Short: 5,000 USD
  → 롱이 많음 → 롱 홀더가 숏에게 펀딩 지급

ETH:
  Long: 8,000 USD
  Short: 12,000 USD
  → 숏이 많음 → 숏 홀더가 롱에게 펀딩 지급

각 토큰마다 독립적인 펀딩 비율!
```

## 🛡️ 리스크 관리

### 토큰별 최대 사용률

```aiken
max_utilization: [
  (BTC, 8000),   // 80% - 안정적
  (ETH, 8000),   // 80% - 안정적
  (ADA, 7000),   // 70% - 더 변동성 큼
  (MEME, 5000),  // 50% - 매우 위험
]
```

**의미:**
- BTC: 풀의 최대 80%까지 BTC 포지션에 사용 가능
- ADA: 풀의 최대 70%까지만 (더 위험하므로)
- MEME 코인: 최대 50%만 (매우 변동성 큼)

### 토큰별 추적의 중요성

```
없다면:
  total_reserved: 80,000 USDC
  어떤 토큰에 얼마나? 모름 😱
  
있다면:
  BTC: 40,000 USDC (40%)
  ETH: 30,000 USDC (30%)
  ADA: 10,000 USDC (10%)
  명확한 리스크 파악 가능! ✅
```

## 💡 실제 사용 예시

### LP (유동성 공급자) 관점

```
Alice가 100,000 USDC를 예치:

자동으로 모든 토큰에 노출:
- BTC 트레이더 수수료 받음
- ETH 트레이더 수수료 받음
- ADA 트레이더 수수료 받음
- 트레이더 손실 = Alice 이익
- 트레이더 이익 = Alice 손실

포트폴리오 효과! 
→ 한 토큰만이 아닌 전체 시장 노출
```

### 트레이더 관점

```
Bob의 전략:
1. BTC 롱 (1,000 USDC, 10x)
2. ETH 숏 (500 USDC, 5x)
3. ADA 롱 (200 USDC, 10x)

모두 같은 USDC 풀 사용!
다양한 전략 동시 실행 가능
```

## 🔧 구현 세부사항

### 포지션 오픈 시 체크사항

```aiken
validate_increase_position:
  1. index_token이 whitelisted_tokens에 있나?
  2. 레버리지가 max_leverage 이하인가?
  3. 이 토큰의 reserved_amount가 max_utilization 이하인가?
  4. 사용자가 충분한 USDC 예치했나?
  5. 수수료 계산 및 차감
  6. Vault의 토큰별 리스트 업데이트:
     - reserved_amounts 업데이트
     - open_interest_long/short 업데이트
     - guaranteed_usd 업데이트 (숏인 경우)
```

### 펀딩 비율 업데이트

```aiken
update_funding_rate:
  for each token in whitelisted_tokens:
    1. 이 토큰의 OI long/short 가져오기
    2. 불균형 계산
    3. 펀딩 비율 계산
    4. cumulative_funding_rate_long 업데이트
    5. cumulative_funding_rate_short 업데이트
    6. last_funding_times 업데이트
```

## 📊 상태 추적 예시

### 실시간 Vault 상태

```json
{
  "stablecoin": "USDC",
  "total_liquidity": "1000000.00",
  "glp_supply": "950000.00",
  
  "tokens": {
    "BTC": {
      "reserved": "150000.00",
      "utilization": "15.0%",
      "open_interest_long": "500000.00",
      "open_interest_short": "200000.00",
      "funding_rate_long": "0.0012",
      "funding_rate_short": "-0.0012"
    },
    "ETH": {
      "reserved": "80000.00",
      "utilization": "8.0%",
      "open_interest_long": "300000.00",
      "open_interest_short": "400000.00",
      "funding_rate_long": "-0.0008",
      "funding_rate_short": "0.0008"
    },
    "ADA": {
      "reserved": "30000.00",
      "utilization": "3.0%",
      "open_interest_long": "100000.00",
      "open_interest_short": "50000.00",
      "funding_rate_long": "0.0005",
      "funding_rate_short": "-0.0005"
    }
  }
}
```

## ✅ 결론

**현재 구현은 완벽히 GMX v1 컨셉을 따릅니다:**

1. ✅ **단일 스테이블 코인 풀** (USDC, USDT 등)
2. ✅ **멀티 에셋 포지션** (BTC, ETH, ADA, ...)
3. ✅ **토큰별 추적** (reserved, OI, funding)
4. ✅ **토큰별 리스크 관리** (max_utilization)
5. ✅ **독립적인 펀딩 비율** (토큰별)
6. ✅ **자본 효율성** (하나의 풀 공유)

이것이 바로 **GMX의 핵심 혁신**이며, Cardano에서 eUTXO 모델로 구현했습니다! 🚀

