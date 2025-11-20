# 스테이블 코인 전용 설계 문서

## 📌 핵심 컨셉

이 프로젝트는 GMX v1의 다중 자산 담보 시스템과 달리, **스테이블 코인만을 담보로 사용**하는 단순화된 영구선물 거래소입니다.

## 🎯 왜 스테이블 코인만?

### 장점

1. **구조 단순화**
   - 여러 토큰의 가격을 추적할 필요 없음
   - 담보 가치 = 예치 금액 (1 USDC = 1 USD)
   - 스왑 기능 불필요

2. **리스크 감소**
   - 담보 자산의 가격 변동성 제거
   - 청산 계산이 더 정확하고 예측 가능
   - 갑작스런 담보 가치 하락 위험 없음

3. **사용자 경험 개선**
   - 사용자는 익숙한 USD 단위로 모든 것을 이해
   - 복잡한 토큰 전환 과정 불필요
   - 명확한 손익 계산

4. **효율성**
   - 트랜잭션 처리가 더 빠름
   - 스마트 컨트랙트 크기 축소
   - 낮은 계산 비용

### 제한사항

1. **자산 다양성**
   - GMX처럼 BTC, ETH를 담보로 사용 불가
   - 사용자는 반드시 스테이블 코인을 보유해야 함

2. **자본 효율성**
   - 다른 암호화폐를 스왑 없이 담보로 활용 불가

## 🏗️ 아키텍처 설명

### Vault 구조

```
VaultDatum {
  stablecoin: AssetClass              // 사용할 스테이블 코인 (예: USDC)
  
  // 유동성 관련
  total_liquidity: Int                // 전체 스테이블 코인 유동성
  reserved_amount: Int                // 포지션에 예약된 금액
  glp_supply: Int                     // 발행된 GLP 총량
  
  // 포지션 추적
  open_interest_long: Int             // 롱 포지션 총 규모
  open_interest_short: Int            // 숏 포지션 총 규모
  guaranteed_usd: Int                 // 숏 포지션 보증 금액
  
  // 펀딩 비율
  cumulative_funding_rate_long: Int   // 롱 누적 펀딩
  cumulative_funding_rate_short: Int  // 숏 누적 펀딩
  last_funding_time: Int              // 마지막 업데이트 시간
  
  // 파라미터
  max_leverage: Int                   // 최대 레버리지
  ...fees
}
```

### Position 구조

```
Position {
  owner: PKH                          // 소유자
  index_token: AssetClass             // 추적 자산 (BTC, ETH 등)
  position_type: Long/Short           // 포지션 타입
  size: Int                           // 포지션 크기 (USD)
  collateral: Int                     // 담보 (스테이블 코인)
  average_price: Int                  // 평균 진입가
  entry_funding_rate: Int             // 진입 시 펀딩
  last_increased_time: Int            // 마지막 증가 시간
}

참고: collateral_token 필드 없음! 항상 Vault의 stablecoin 사용
```

## 💰 주요 흐름

### 1. 유동성 공급

```
사용자 → [1000 USDC] → Vault

Vault:
  total_liquidity += 1000
  glp_to_mint = 1000 * glp_supply / total_liquidity (기존 공급이 있는 경우)
  glp_supply += glp_to_mint

사용자 ← [GLP 토큰]
```

### 2. 롱 포지션 오픈 (예: BTC 롱)

```
사용자 → [100 USDC 담보 + 수수료] → Vault
요청: BTC 롱, 10x 레버리지

Vault:
  reserved_amount += 100
  open_interest_long += 1000  // 100 * 10
  
Position UTXO 생성:
  size = 1000 USD
  collateral = 100 USDC (스테이블 코인으로 저장)
  index_token = BTC
  average_price = 현재 BTC 가격
```

### 3. 포지션 종료

```
Oracle → 현재 BTC 가격 조회

PnL 계산:
  entry_price = 40,000 USD
  current_price = 44,000 USD
  PnL = 1000 * (44000 - 40000) / 40000 = 100 USD 이익

수수료 차감:
  payout = 100 (담보) + 100 (이익) - 수수료

Vault → [200 USDC] → 사용자

Vault:
  reserved_amount -= 100
  open_interest_long -= 1000
  total_liquidity -= 100 (이익은 풀에서 지급)
```

## 🔄 펀딩 비율

스테이블 코인 전용 설계에서도 펀딩 비율은 중요합니다:

```
롱 오픈 인터레스트 > 숏 오픈 인터레스트
→ 롱이 숏에게 펀딩 지급

목적:
- 롱/숏 균형 유지
- 한쪽으로 치우치는 것 방지
```

**펀딩 비율 계산:**

```aiken
imbalance = (open_interest_long - open_interest_short) 
          / (open_interest_long + open_interest_short)

funding_rate = imbalance * time_elapsed * factor
```

## 🎨 사용 예시

### 시나리오 1: LP (유동성 공급자)

Alice는 GLP 홀더가 되고 싶어합니다:

1. 10,000 USDC를 Vault에 예치
2. GLP 토큰 받음 (민트 수수료 0.3% 차감 후)
3. 트레이더들의 수수료를 받음
4. 트레이더들의 손실이 풀의 이익
5. 트레이더들의 이익은 풀에서 지급 (위험)

### 시나리오 2: 트레이더 (롱 포지션)

Bob은 BTC 가격이 오를 것으로 예상:

1. 1,000 USDC를 담보로 예치
2. BTC 롱 포지션 오픈, 10x 레버리지
3. 포지션 크기: 10,000 USD
4. BTC 가격 10% 상승 시 → 1,000 USD 이익 (100% 수익!)
5. BTC 가격 10% 하락 시 → 1,000 USD 손실 (청산)

### 시나리오 3: 트레이더 (숏 포지션)

Carol은 ETH 가격이 떨어질 것으로 예상:

1. 500 USDC를 담보로 예치
2. ETH 숏 포지션 오픈, 5x 레버리지
3. 포지션 크기: 2,500 USD
4. ETH 가격 8% 하락 시 → 200 USD 이익
5. ETH 가격 20% 상승 시 → 청산

## ⚠️ 중요 제약사항

### 1. 지원하는 스테이블 코인

Vault는 **하나의 스테이블 코인만** 지정합니다:
- USDC, USDT, DAI, 또는 Cardano 네이티브 스테이블 중 선택
- 배포 시 `VaultDatum.stablecoin` 필드에 지정
- 이후 변경 불가 (새 Vault 배포 필요)

### 2. 스테이블 코인 간 전환

다른 스테이블을 사용하려면:
- 외부 DEX에서 스왑 후 사용
- 또는 여러 Vault를 배포 (USDC Vault, USDT Vault 등)

### 3. 가격 페그 리스크

스테이블 코인이 1 USD에서 벗어나면:
- 담보 가치가 실제로 변동
- 하지만 컨트랙트는 1 USD로 간주
- USDC/USDT 같은 안정적인 스테이블 사용 권장

## 🔧 향후 개선 가능성

### 옵션 1: 다중 스테이블 지원

여러 스테이블을 1:1로 교환 허용:
- USDC, USDT, DAI를 모두 $1로 취급
- 간단한 스왑 기능 추가

### 옵션 2: Vault 분리

각 스테이블마다 별도 Vault:
- USDC Vault
- USDT Vault
- iUSD Vault (Cardano 네이티브)

### 옵션 3: 자동 변환

예치 시 다른 자산을 자동으로 스테이블로 변환:
- 사용자가 ADA 예치 → DEX에서 USDC로 스왑 → Vault에 예치
- 오프체인 애그리게이터에서 처리

## 📊 비교: GMX vs BaobabX

| 항목 | GMX v1 | BaobabX |
|------|--------|---------|
| 담보 자산 | BTC, ETH, USDC, USDT 등 | **USDC만** (예시) |
| 담보 가치 계산 | 오라클 가격 필요 | 항상 1 USD |
| Swap | 필요 (토큰 간) | 불필요 |
| 복잡도 | 높음 | **낮음** |
| 가스 비용 | 높음 (Ethereum) | 낮음 (Cardano) |
| 사용자 혼란 | 다양한 옵션 | **단순함** |

## 🎓 결론

스테이블 코인 전용 설계는:
- ✅ 단순하고 이해하기 쉬움
- ✅ 낮은 리스크
- ✅ 빠른 개발 및 감사
- ✅ Cardano의 eUTXO 모델과 잘 맞음
- ❌ 자산 다양성 제한

이는 **MVP(Minimum Viable Product)로 이상적**이며, 향후 다중 자산으로 확장할 수 있는 기반을 제공합니다.

