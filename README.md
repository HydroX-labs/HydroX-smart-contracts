# BaobabX GMX - Perpetual Exchange on Cardano

GMX v1 스타일의 탈중앙화 영구선물 거래소를 Cardano Aiken으로 구현한 스마트 컨트랙트입니다.

**주요 특징: 스테이블 코인 전용 담보 시스템**
- 유동성 풀은 단일 스테이블 코인만 보유
- 모든 포지션의 담보는 스테이블 코인으로만 예치
- 구조가 단순하고 가격 변동성 리스크 최소화

## 🏗️ 아키텍처

### 핵심 컴포넌트

#### 1. **Vault Contract** (`validators/vault.ak`)
- 스테이블 코인 유동성 풀 관리
- 레버리지 포지션의 담보 보관 (스테이블 코인만)
- GLP 토큰 발행/소각
- 펀딩 비율 관리
- 수수료 관리

**주요 기능:**
- `AddLiquidity`: 스테이블 코인 예치 및 GLP 발행
- `RemoveLiquidity`: GLP 소각 및 스테이블 코인 회수
- `IncreasePosition`: 포지션 오픈/증가 (스테이블 코인 담보)
- `DecreasePosition`: 포지션 감소/종료
- `LiquidatePosition`: 청산
- `UpdateFundingRate`: 펀딩 비율 업데이트

#### 2. **Position Contract** (`validators/position.ak`)
- 개별 포지션 관리
- 포지션 소유권 검증
- 포지션 업데이트/종료

**데이터 구조:**
```
Position {
  owner: 소유자 공개키 해시
  index_token: 인덱스 토큰 (가격 추적 대상, 예: BTC, ETH)
  position_type: Long/Short
  size: 포지션 크기 (USD, 1e30 스케일)
  collateral: 담보 금액 (스테이블 코인, 1e30 스케일)
  average_price: 평균 진입 가격
  entry_funding_rate: 진입 시 펀딩 비율
  last_increased_time: 마지막 증가 시간
}

참고: 담보는 항상 Vault의 스테이블 코인으로 고정
```

#### 3. **Oracle Contract** (`validators/oracle.ak`)
- 가격 피드 관리
- 가격 데이터 업데이트
- 오라클 관리자 권한 관리

**가격 데이터:**
```
PriceData {
  token: 토큰 식별자
  price: USD 가격 (1e30 스케일)
  timestamp: 타임스탬프
  confidence: 신뢰도
}
```

### 유틸리티 (`lib/utils.ak`)

주요 헬퍼 함수:
- `calculate_fee()`: 수수료 계산
- `get_aum()`: AUM(운용자산총액) 계산
- `get_position_fee()`: 포지션 수수료
- `get_funding_fee()`: 펀딩 수수료
- `validate_liquidation()`: 청산 조건 검증

## 📊 GMX v1 vs BaobabX 구현

| 기능 | GMX v1 (이더리움) | BaobabX (Cardano) |
|------|-------------------|-------------------|
| 담보 자산 | 다중 자산 (ETH, BTC, USDC 등) | **스테이블 코인만** |
| GLP 토큰 | ERC-20 | Cardano 네이티브 토큰 |
| 상태 저장 | 단일 Vault 컨트랙트 | Vault UTXO + datum |
| 포지션 저장 | Position mapping | 개별 Position UTXO |
| 오라클 | Chainlink | Oracle UTXO + datum |
| 스왑 기능 | ✅ 다중 자산 간 스왑 | ❌ 불필요 (단일 자산) |
| 동시 처리 | 순차적 | 병렬 가능 (eUTXO) |
| Gas 최적화 | 높은 gas 비용 | 예측 가능한 수수료 |

## 🔧 주요 설계 결정

### 1. **스테이블 코인 전용 설계**
- Vault는 하나의 스테이블 코인만 보유 (예: USDC, USDT, iUSD)
- 모든 담보는 해당 스테이블 코인으로만 예치
- 가격 변동 리스크 최소화 (스테이블 = 1 USD)
- 다중 자산 관리의 복잡성 제거

### 2. **eUTXO 모델 활용**
- Vault는 단일 UTXO로 관리 (상태가 datum에 저장)
- 각 포지션은 개별 UTXO (병렬 처리 가능)
- Oracle도 별도 UTXO로 가격 피드 제공

### 3. **간소화된 Datum 구조**
- `VaultDatum`: 
  - `stablecoin`: 사용할 스테이블 코인 지정
  - `total_liquidity`: 전체 유동성
  - `reserved_amount`: 포지션 예약 금액
  - `open_interest_long/short`: 롱/숏 오픈 인터레스트
  - Fee parameters, funding rates
- `PositionDatum`: 개별 포지션 정보 (담보 토큰 불필요)
- `OracleDatum`: 인덱스 토큰 가격 데이터 (BTC, ETH 등)

### 4. **Redeemer 액션**
- 각 작업은 명시적 redeemer로 구분
- 검증 로직은 각 액션별로 분리
- Swap 기능 제거 (단일 자산이므로 불필요)

### 5. **정밀도 처리**
- 가격: 1e30 스케일 (GMX와 동일)
- 스테이블 코인 금액: 1e30 스케일
- 수수료: 베이시스 포인트 (1bp = 0.01%)
- 펀딩 비율: 1e6 정밀도

## 🚀 개발 로드맵

### Phase 1: 코어 기능 (현재)
- [x] 기본 타입 정의
- [x] Vault 검증자 구조
- [x] Position 검증자 구조
- [x] Oracle 검증자 구조
- [ ] 유틸리티 함수 완성

### Phase 2: 검증 로직 구현
- [ ] Add/Remove 유동성 검증 완성
- [ ] 포지션 증가/감소 검증 완성
- [ ] 청산 로직 완성
- [ ] 스왑 기능 완성
- [ ] 수수료 계산 및 분배

### Phase 3: 오라클 통합
- [ ] 가격 피드 검증
- [ ] 가격 신선도 체크
- [ ] 다중 오라클 지원

### Phase 4: 테스트 및 최적화
- [ ] 단위 테스트
- [ ] 통합 테스트
- [ ] 가스 최적화
- [ ] 보안 감사

### Phase 5: 프론트엔드 및 배포
- [ ] Off-chain 코드 (Lucid/Mesh)
- [ ] 웹 인터페이스
- [ ] 테스트넷 배포
- [ ] 메인넷 배포

## 💡 다음 단계

1. **유틸리티 함수 완성**
   ```
   - AUM 계산 최종 검증
   - PnL 계산 로직
   - 청산 조건 체크
   ```

2. **Vault 검증 로직 구현**
   ```
   - 유동성 추가/제거 완전 구현
   - GLP 발행/소각 메커니즘
   - 포지션 관리 로직
   ```

3. **오프체인 통합**
   ```
   - Lucid/Mesh를 사용한 트랜잭션 빌더
   - 가격 피드 업데이터
   - 포지션 모니터링
   ```

4. **테스트 작성**
   ```
   - Aiken 테스트 프레임워크
   - 시나리오 기반 테스트
   ```

## 📝 사용 예시

### 유동성 추가
```typescript
// Off-chain code (예시)
const tx = await lucid
  .newTx()
  .collectFrom([vaultUtxo])
  .payToContract(vaultAddress, {
    inline: updatedVaultDatum
  })
  .attachSpendingValidator(vaultValidator)
  .mintAssets({ [glpToken]: glpAmount })
  .complete();
```

### 롱 포지션 열기
```typescript
const tx = await lucid
  .newTx()
  .collectFrom([vaultUtxo])
  .payToContract(vaultAddress, {
    inline: updatedVaultDatum
  })
  .payToContract(positionAddress, {
    inline: positionDatum
  })
  .complete();
```

## 🔐 보안 고려사항

1. **가격 오라클**: Chainlink 스타일의 신뢰할 수 있는 가격 피드 필요
2. **청산 메커니즘**: 적절한 청산 인센티브 설정
3. **펀딩 비율**: 롱/숏 밸런스 유지
4. **관리자 권한**: 멀티시그 또는 DAO 거버넌스 고려

## 🚀 시작하기

### Aiken 설치

```bash
# Windows (PowerShell)
winget install aiken-lang.aiken

# 또는 Cargo로 설치
cargo install aiken

# 또는 바이너리 다운로드
# https://github.com/aiken-lang/aiken/releases
```

### 프로젝트 빌드

```bash
# 의존성 설치
aiken check

# 빌드
aiken build

# 테스트 (추가 후)
aiken test
```

### 프로젝트 구조

```
baobabX-smart-contracts/
├── aiken.toml                 # 프로젝트 설정
├── lib/
│   ├── types.ak              # 데이터 타입 정의
│   └── utils.ak              # 유틸리티 함수
├── validators/
│   ├── vault.ak              # Vault 검증자 (메인 로직)
│   ├── position.ak           # Position 검증자
│   └── oracle.ak             # Oracle 검증자
└── README.md                 # 이 파일
```

## 🔥 주요 기능 시나리오

### 유동성 제공:
1. 사용자가 **스테이블 코인**(예: USDC)을 Vault에 예치
2. Vault가 GLP 토큰 발행
3. GLP 가격은 total_liquidity / GLP Supply로 계산
4. 발행 수수료(mint_fee) 차감 후 GLP 받음

### 롱 포지션 오픈 (예: BTC 롱):
1. **스테이블 코인** 담보 예치 (예: 1,000 USDC)
2. BTC 가격에 대한 롱 포지션 생성
3. 레버리지 적용 (예: 10x → 10,000 USD 포지션)
4. 마진 수수료 차감
5. Position UTXO 생성
6. Vault의 reserved_amount 증가

### 숏 포지션 오픈 (예: ETH 숏):
1. **스테이블 코인** 담보 예치
2. ETH 가격에 대한 숏 포지션 생성
3. 레버리지 적용
4. Position UTXO 생성
5. Vault의 guaranteed_usd 증가

### 포지션 종료:
1. 오라클에서 현재 가격 조회
2. PnL 계산 (Long/Short에 따라)
3. 펀딩 비율 및 수수료 차감
4. **스테이블 코인**으로 담보 + 이익 반환
5. Position UTXO 소각
6. Vault 상태 업데이트

### 청산:
1. 포지션의 담보 비율이 최소값(1%) 이하로 하락
2. 청산자가 청산 트랜잭션 제출
3. 청산자에게 청산 수수료 지급
4. 남은 담보는 풀로 반환
5. Position UTXO 소각

## 💻 오프체인 통합

### 트랜잭션 빌더 예시 (Lucid)

```typescript
import { Lucid, Blockfrost, Data } from "lucid-cardano";

// Lucid 초기화
const lucid = await Lucid.new(
  new Blockfrost("https://cardano-preview.blockfrost.io/api/v0", "your-api-key"),
  "Preview"
);

// 스테이블 코인 정의 (예: USDC)
const STABLECOIN = {
  policyId: "your_stablecoin_policy_id",
  assetName: "USDC"
};

// 1. 유동성 추가 (스테이블 코인 예치)
const addLiquidityTx = await lucid
  .newTx()
  .collectFrom([vaultUtxo], Data.to(new Constr(0, [amount]))) // AddLiquidity redeemer
  .payToContract(
    vaultAddress, 
    { inline: Data.to(updatedVaultDatum) }, 
    { 
      [STABLECOIN.policyId + STABLECOIN.assetName]: 
        vaultDatum.total_liquidity + amount 
    }
  )
  .mintAssets({ [glpPolicyId + glpAssetName]: glpAmount }, Data.to(glpRedeemer))
  .complete();

// 2. 롱 포지션 오픈 (BTC 롱, 10x 레버리지)
const openLongTx = await lucid
  .newTx()
  .collectFrom([vaultUtxo], Data.to(
    new Constr(2, [ // IncreasePosition redeemer
      userPkh,
      btcAssetClass,
      collateralAmount,  // 1000 USDC
      sizeAmount,        // 10000 USD (10x)
      true               // is_long
    ])
  ))
  .payToContract(vaultAddress, { inline: Data.to(updatedVaultDatum) }, updatedVaultAssets)
  .payToContract(positionAddress, { inline: Data.to(positionDatum) }, {})
  .complete();

const signedTx = await openLongTx.sign().complete();
const txHash = await signedTx.submit();
```

### 가격 오라클 업데이터

```typescript
// 오라클 가격 업데이트 (오라클 키퍼가 실행)
async function updateOraclePrices(prices: PriceData[]) {
  const oracleUtxo = await findOracleUtxo();
  const newOracleDatum = {
    prices: prices,
    oracle_admin: oracleAdmin,
    max_price_age: maxAge
  };
  
  const tx = await lucid
    .newTx()
    .collectFrom([oracleUtxo], oracleRedeemer)
    .payToContract(oracleAddress, { inline: Data.to(newOracleDatum) })
    .addSigner(oracleAdminAddress)
    .complete();
    
  return tx;
}
```

## 🎯 GMX v1 기능 비교

| 기능 | GMX v1 | BaobabX 구현 | 상태 |
|------|--------|--------------|------|
| 다중 자산 풀 | ✅ (BTC, ETH, USDC 등) | ❌ **스테이블 코인만** | ✅ 구조 완성 |
| 롱 포지션 | ✅ | ✅ | 구현 대기 |
| 숏 포지션 | ✅ | ✅ | 구현 대기 |
| 청산 | ✅ | ✅ | 구현 대기 |
| 펀딩 비율 | ✅ | ✅ (롱/숏 밸런싱) | 구현 대기 |
| GLP 토큰 | ✅ ERC-20 | ✅ 네이티브 토큰 | 구현 대기 |
| 토큰 스왑 | ✅ | ❌ 불필요 | N/A |
| 가격 피드 | Chainlink | Oracle UTXO | ✅ 구조 완성 |
| 수수료 분배 | ✅ | ✅ GLP 홀더에게 | 구현 대기 |
| 레버리지 | 최대 50x | 설정 가능 (max_leverage) | ✅ 구조 완성 |

### 주요 차이점

**단순화된 부분:**
- ✅ 스테이블 코인만 사용 → 담보 가치 계산 단순화
- ✅ Swap 기능 제거 → 코드 복잡도 감소
- ✅ 단일 유동성 풀 → 관리 용이

**Cardano 특화:**
- ✅ eUTXO 모델로 병렬 처리 가능
- ✅ 네이티브 토큰 (GLP)
- ✅ 예측 가능한 트랜잭션 비용

## 🧪 테스트 전략

### 단위 테스트
```aiken
test calculate_fee_correct() {
  let amount = 1000000
  let fee_bp = 30  // 0.3%
  let fee = calculate_fee(amount, fee_bp)
  fee == 3000
}

test validate_liquidation_underwater() {
  // 포지션이 물에 잠겼을 때 청산 테스트
  let should_liquidate = validate_liquidation(
    position_size: 10000,
    position_collateral: 1000,
    margin_fees: 100,
    funding_fees: 50,
    has_profit: False,
    delta: 1200,  // 손실이 담보를 초과
    liquidation_fee_usd: 10
  )
  should_liquidate == True
}
```

### 통합 테스트
- 전체 유동성 공급 플로우
- 완전한 포지션 라이프사이클 (오픈 → 증가 → 감소 → 종료)
- 청산 시나리오
- 다중 사용자 상호작용

## 📚 참고 자료

- [GMX Contracts (v1)](https://github.com/gmx-io/gmx-contracts)
- [Aiken Documentation](https://aiken-lang.org)
- [Cardano eUTXO Model](https://docs.cardano.org/plutus/eutxo-explainer)
- [Lucid Documentation](https://lucid.spacebudz.io/)

## 🤝 기여

이 프로젝트는 개발 초기 단계입니다. 기여를 환영합니다!

### 기여 방법
1. 레포지토리 포크
2. 기능 브랜치 생성
3. 변경사항 작성
4. 테스트 작성
5. Pull request 제출

## 📄 라이선스

Apache-2.0

## 🙏 감사의 말

- GMX 팀의 오리지널 디자인
- Aiken-lang 팀의 훌륭한 Cardano 스마트 컨트랙트 언어
- Cardano 커뮤니티의 eUTXO 모델 혁신

## ⚠️ 면책 조항

이것은 실험적인 소프트웨어입니다. 사용에 따른 위험은 본인이 부담합니다. 메인넷에 배포하기 전에 항상 철저한 보안 감사를 수행하세요.
