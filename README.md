# BaobabX GMX - Perpetual Exchange on Cardano

GMX v1 스타일의 탈중앙화 영구선물 거래소를 Cardano Aiken으로 구현한 스마트 컨트랙트입니다.

## 🏗️ 아키텍처

### 핵심 컴포넌트

#### 1. **Vault Contract** (`validators/vault.ak`)
- 유동성 풀 관리
- 레버리지 포지션의 담보 보관
- GLP 토큰 발행/소각
- 스왑 기능
- 수수료 관리

**주요 기능:**
- `AddLiquidity`: 유동성 공급 및 GLP 발행
- `RemoveLiquidity`: 유동성 회수 및 GLP 소각
- `IncreasePosition`: 포지션 증가
- `DecreasePosition`: 포지션 감소
- `LiquidatePosition`: 청산
- `Swap`: 토큰 스왑

#### 2. **Position Contract** (`validators/position.ak`)
- 개별 포지션 관리
- 포지션 소유권 검증
- 포지션 업데이트/종료

**데이터 구조:**
```
Position {
  owner: 소유자 공개키 해시
  collateral_token: 담보 토큰
  index_token: 인덱스 토큰 (가격 추적 대상)
  position_type: Long/Short
  size: 포지션 크기 (USD, 1e30 스케일)
  collateral: 담보 금액
  average_price: 평균 진입 가격
  entry_funding_rate: 진입 시 펀딩 비율
  ...
}
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

## 📊 GMX v1 vs Cardano 구현

| GMX v1 (이더리움) | Cardano/Aiken 구현 |
|-------------------|-------------------|
| ERC-20 GLP 토큰 | Cardano 네이티브 토큰 |
| 단일 Vault 컨트랙트 | Vault UTXO + 상태 datum |
| Position mapping | 개별 Position UTXO |
| Chainlink Oracle | Oracle UTXO + 가격 datum |
| Event logs | Transaction metadata |
| Gas-based fees | Transaction fees + 프로토콜 수수료 |

## 🔧 주요 설계 결정

### 1. **eUTXO 모델 활용**
- Vault는 단일 UTXO로 관리 (상태가 datum에 저장)
- 각 포지션은 개별 UTXO (병렬 처리 가능)
- Oracle도 별도 UTXO로 가격 피드 제공

### 2. **Datum 구조**
- `VaultDatum`: 풀 상태, 예약 금액, 수수료 파라미터
- `PositionDatum`: 개별 포지션 정보 + Vault 참조
- `OracleDatum`: 토큰별 가격 데이터

### 3. **Redeemer 액션**
- 각 작업은 명시적 redeemer로 구분
- 검증 로직은 각 액션별로 분리

### 4. **정밀도 처리**
- 가격: 1e30 스케일 (GMX와 동일)
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

## 📚 참고자료

- [GMX Contracts (v1)](https://github.com/gmx-io/gmx-contracts)
- [Aiken Documentation](https://aiken-lang.org)
- [Cardano eUTXO Model](https://docs.cardano.org/plutus/eutxo-explainer)

## 🤝 기여

이 프로젝트는 개발 초기 단계입니다. 기여를 환영합니다!

## 📄 라이선스

Apache-2.0

