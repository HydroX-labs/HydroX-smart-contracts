# 오프체인 아키텍처 가이드

## 🔑 핵심 차이점: Ethereum vs Cardano

### Ethereum (Account-based, State Model)

```typescript
// Ethereum에서 포지션 오픈 (간단!)
const tx = await vaultContract.increasePosition(
  indexToken,
  amountIn,
  sizeDelta,
  isLong
);
await tx.wait();

// 끝! EVM이 알아서:
// 1. Storage 상태 읽기
// 2. 로직 실행 (수수료 계산, 포지션 생성 등)
// 3. 상태 업데이트
// 4. 이벤트 발생
```

**특징:**
- ✅ 백엔드는 단순히 함수 호출만 하면 됨
- ✅ 온체인에서 모든 계산 수행
- ❌ 실행 전까지 정확한 가스비 모름
- ❌ 트랜잭션 실행 후 실패 가능
- ❌ 순차적 처리 (한 번에 하나씩)

### Cardano (UTXO-based, Validator Model)

```typescript
// Cardano에서 포지션 오픈 (복잡!)

// 1. Vault UTXO 찾기
const vaultUtxo = await findVaultUtxo();
const vaultDatum = await parseVaultDatum(vaultUtxo);

// 2. 오라클에서 가격 가져오기
const oracleUtxo = await findOracleUtxo();
const btcPrice = await getBtcPrice(oracleUtxo);

// 3. 백엔드에서 모든 계산 수행
const collateral = 1000; // USDC
const leverage = 10;
const size = collateral * leverage;
const marginFee = calculateFee(size, vaultDatum.margin_fee_basis_points);
const totalCost = collateral + marginFee;

// 4. 새로운 상태 계산
const newVaultDatum = {
  ...vaultDatum,
  reserved_amount: vaultDatum.reserved_amount + collateral,
  open_interest_long: vaultDatum.open_interest_long + size,
  total_liquidity: vaultDatum.total_liquidity + marginFee, // 수수료 추가
};

const positionDatum = {
  owner: userPkh,
  index_token: btcAssetClass,
  position_type: "Long",
  size: size,
  collateral: collateral,
  average_price: btcPrice,
  entry_funding_rate: vaultDatum.cumulative_funding_rate_long,
  last_increased_time: currentTime,
};

// 5. 트랜잭션 구성 (백엔드에서!)
const tx = await lucid
  .newTx()
  // Input: 기존 Vault UTXO 소비
  .collectFrom([vaultUtxo], Data.to(increasePositionRedeemer))
  // Input: 사용자의 스테이블 코인
  .collectFrom(userUtxos, Data.void())
  // Input: 오라클 참조 (읽기만)
  .readFrom([oracleUtxo])
  // Output: 업데이트된 Vault
  .payToContract(vaultAddress, {
    inline: Data.to(newVaultDatum)
  }, {
    [stablecoinAsset]: vaultDatum.total_liquidity + totalCost
  })
  // Output: 새로운 Position UTXO
  .payToContract(positionAddress, {
    inline: Data.to(positionDatum)
  }, {})
  // Output: 잔돈 반환
  .payToAddress(userAddress, changeAssets)
  .complete();

// 6. 서명 및 제출
const signedTx = await tx.sign().complete();
const txHash = await signedTx.submit();

// 온체인 validator는 단지 검증만 함:
// "이 트랜잭션이 규칙을 따르는가?" → True/False
```

**특징:**
- ❌ 백엔드가 **모든 것**을 계산해야 함
- ❌ UTXO 찾기, 상태 계산, 트랜잭션 구성 등
- ✅ 제출 전에 로컬에서 완전히 검증 가능
- ✅ 수수료 정확히 예측 가능
- ✅ 실패하면 제출 전에 알 수 있음
- ✅ 병렬 처리 가능 (다른 UTXO 사용)

## 🏗️ BaobabX GMX 오프체인 아키텍처

### 필요한 컴포넌트

```
┌─────────────────────────────────────────────────────────┐
│                     Frontend (React)                     │
│  - 사용자 인터페이스                                      │
│  - Wallet 연결 (Nami, Eternl 등)                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│              Transaction Builder (TypeScript)            │
│  - Lucid/Mesh 사용                                       │
│  - UTXO 관리                                             │
│  - Datum 계산                                            │
│  - 트랜잭션 구성                                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│               Backend Services (Node.js)                 │
│  ┌───────────────────────────────────────────────────┐  │
│  │ UTXO Indexer                                      │  │
│  │ - Vault UTXO 추적                                 │  │
│  │ - Position UTXO 추적                              │  │
│  │ - 빠른 조회를 위한 DB                             │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Oracle Service                                    │  │
│  │ - 가격 피드 업데이트                              │  │
│  │ - Chainlink, Pyth 등에서 데이터 가져오기         │  │
│  │ - Oracle UTXO 업데이트                            │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Liquidation Bot                                   │  │
│  │ - 청산 가능한 포지션 모니터링                     │  │
│  │ - 자동 청산 실행                                  │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Funding Rate Updater                              │  │
│  │ - 주기적으로 펀딩 비율 계산                       │  │
│  │ - Vault 업데이트                                  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│              Cardano Blockchain                          │
│  - Vault Validator                                       │
│  - Position Validator                                    │
│  - Oracle Validator                                      │
└─────────────────────────────────────────────────────────┘
```

## 💻 핵심 오프체인 코드 예시

### 1. UTXO Indexer

```typescript
// utxo-indexer.ts
import { Lucid, Blockfrost } from "lucid-cardano";

class VaultIndexer {
  private vaultAddress: string;
  private db: Database; // PostgreSQL, MongoDB 등
  
  async indexVaultUtxo() {
    // 1. Vault address의 모든 UTXO 조회
    const utxos = await this.lucid.utxosAt(this.vaultAddress);
    
    // 2. 가장 최신 Vault UTXO 찾기 (가장 큰 value)
    const vaultUtxo = utxos.reduce((max, utxo) => 
      utxo.assets.lovelace > max.assets.lovelace ? utxo : max
    );
    
    // 3. Datum 파싱
    const vaultDatum = await this.parseVaultDatum(vaultUtxo);
    
    // 4. DB에 저장 (빠른 조회용)
    await this.db.vaults.upsert({
      utxo_ref: `${vaultUtxo.txHash}#${vaultUtxo.outputIndex}`,
      datum: vaultDatum,
      total_liquidity: vaultDatum.total_liquidity,
      reserved_amount: vaultDatum.reserved_amount,
      glp_supply: vaultDatum.glp_supply,
      updated_at: new Date(),
    });
    
    return vaultUtxo;
  }
  
  async indexPositions() {
    // Position address의 모든 UTXO 조회
    const positionUtxos = await this.lucid.utxosAt(this.positionAddress);
    
    for (const utxo of positionUtxos) {
      const positionDatum = await this.parsePositionDatum(utxo);
      
      // 각 포지션을 DB에 저장
      await this.db.positions.upsert({
        utxo_ref: `${utxo.txHash}#${utxo.outputIndex}`,
        owner: positionDatum.owner,
        index_token: positionDatum.index_token,
        size: positionDatum.size,
        collateral: positionDatum.collateral,
        is_long: positionDatum.position_type === "Long",
        // ... 기타 필드
      });
    }
  }
  
  // 실시간 업데이트 (Blockfrost webhook 또는 polling)
  async watchVault() {
    setInterval(async () => {
      await this.indexVaultUtxo();
      await this.indexPositions();
    }, 10000); // 10초마다
  }
}
```

### 2. Transaction Builder

```typescript
// transaction-builder.ts
import { Data } from "lucid-cardano";

class PositionBuilder {
  async openLongPosition(
    user: {
      address: string;
      pkh: string;
      utxos: UTxO[];
    },
    params: {
      indexToken: AssetClass;
      collateral: bigint;
      leverage: number;
    }
  ) {
    // 1. 필요한 UTXO들 가져오기
    const vaultUtxo = await this.indexer.getVaultUtxo();
    const vaultDatum = this.parseVaultDatum(vaultUtxo.datum);
    const oracleUtxo = await this.indexer.getOracleUtxo();
    const price = await this.getPrice(oracleUtxo, params.indexToken);
    
    // 2. 계산 (백엔드에서!)
    const size = params.collateral * BigInt(params.leverage);
    const marginFee = this.calculateFee(
      size, 
      vaultDatum.margin_fee_basis_points
    );
    const totalCost = params.collateral + marginFee;
    
    // 3. 레버리지 검증 (로컬에서!)
    if (params.leverage > vaultDatum.max_leverage) {
      throw new Error(`Max leverage is ${vaultDatum.max_leverage}x`);
    }
    
    // 4. 유동성 검증 (로컬에서!)
    const utilization = this.calculateUtilization(
      vaultDatum.total_liquidity,
      vaultDatum.reserved_amount + params.collateral
    );
    if (utilization > 9500) { // 95%
      throw new Error("Insufficient liquidity");
    }
    
    // 5. 새로운 Vault datum 계산
    const newVaultDatum: VaultDatum = {
      ...vaultDatum,
      total_liquidity: vaultDatum.total_liquidity + marginFee,
      reserved_amount: vaultDatum.reserved_amount + params.collateral,
      open_interest_long: vaultDatum.open_interest_long + size,
    };
    
    // 6. Position datum 생성
    const positionDatum: PositionDatum = {
      position: {
        owner: user.pkh,
        index_token: params.indexToken,
        position_type: { Long: [] },
        size: size,
        collateral: params.collateral,
        average_price: price,
        entry_funding_rate: vaultDatum.cumulative_funding_rate_long,
        last_increased_time: Date.now(),
      },
      vault_ref: `${vaultUtxo.txHash}#${vaultUtxo.outputIndex}`,
    };
    
    // 7. Redeemer 구성
    const vaultRedeemer = Data.to(
      new Constr(2, [ // IncreasePosition
        Data.fromJson(user.pkh),
        Data.fromJson(params.indexToken),
        Data.fromJson(params.collateral),
        Data.fromJson(size),
        Data.fromJson(true), // is_long
      ])
    );
    
    // 8. 사용자 UTXO에서 스테이블 코인 선택
    const stablecoinUtxos = this.selectStablecoinUtxos(
      user.utxos, 
      vaultDatum.stablecoin,
      totalCost
    );
    
    // 9. 트랜잭션 구성
    const tx = await this.lucid
      .newTx()
      // Vault UTXO 소비
      .collectFrom([vaultUtxo], vaultRedeemer)
      // 사용자 스테이블 코인 소비
      .collectFrom(stablecoinUtxos, Data.void())
      // 오라클 참조 (읽기만, 소비 안 함)
      .readFrom([oracleUtxo])
      // 새로운 Vault UTXO
      .payToContract(
        this.vaultAddress,
        { inline: Data.to(newVaultDatum) },
        {
          lovelace: 2000000n, // Min ADA
          [this.getAssetId(vaultDatum.stablecoin)]: 
            vaultDatum.total_liquidity + totalCost
        }
      )
      // 새로운 Position UTXO
      .payToContract(
        this.positionAddress,
        { inline: Data.to(positionDatum) },
        { lovelace: 2000000n }
      )
      // Vault validator 첨부
      .attachSpendingValidator(this.vaultValidator)
      .complete();
    
    // 10. 비용 추정 (제출 전!)
    const fee = tx.fee;
    console.log(`Estimated fee: ${fee / 1000000n} ADA`);
    
    return tx;
  }
  
  // 유틸리티 함수들
  private calculateFee(amount: bigint, basisPoints: bigint): bigint {
    return (amount * basisPoints) / 10000n;
  }
  
  private calculateUtilization(
    totalLiquidity: bigint, 
    reservedAmount: bigint
  ): number {
    return Number((reservedAmount * 10000n) / totalLiquidity);
  }
  
  private selectStablecoinUtxos(
    utxos: UTxO[], 
    stablecoin: AssetClass,
    required: bigint
  ): UTxO[] {
    // Coin selection algorithm
    // ...
  }
}
```

### 3. Liquidation Bot

```typescript
// liquidation-bot.ts
class LiquidationBot {
  async monitorPositions() {
    while (true) {
      try {
        // 1. 모든 포지션 조회
        const positions = await this.indexer.getAllPositions();
        const oracleUtxo = await this.indexer.getOracleUtxo();
        
        for (const position of positions) {
          // 2. 현재 가격 가져오기
          const currentPrice = await this.getPrice(
            oracleUtxo, 
            position.index_token
          );
          
          // 3. PnL 계산
          const { hasProfit, pnl } = this.calculatePnL(
            position,
            currentPrice
          );
          
          // 4. 수수료 계산
          const fees = this.calculateFees(position);
          
          // 5. 청산 가능 여부 확인
          const shouldLiquidate = this.validateLiquidation(
            position,
            hasProfit,
            pnl,
            fees
          );
          
          if (shouldLiquidate) {
            console.log(`Liquidating position: ${position.utxo_ref}`);
            await this.liquidatePosition(position);
          }
        }
      } catch (error) {
        console.error("Liquidation bot error:", error);
      }
      
      await this.sleep(5000); // 5초마다 체크
    }
  }
  
  private async liquidatePosition(position: Position) {
    // Liquidation 트랜잭션 구성
    const tx = await this.builder.buildLiquidationTx(position);
    const signedTx = await tx.sign().complete();
    const txHash = await signedTx.submit();
    
    console.log(`Liquidation submitted: ${txHash}`);
  }
  
  private validateLiquidation(
    position: Position,
    hasProfit: boolean,
    pnl: bigint,
    fees: bigint
  ): boolean {
    const remainingCollateral = hasProfit
      ? position.collateral + pnl - fees
      : position.collateral - pnl - fees;
    
    // 담보 비율 < 1%면 청산
    const collateralRatio = 
      (remainingCollateral * 10000n) / position.size;
    
    return collateralRatio < 100n; // 1%
  }
}
```

### 4. Oracle Price Updater

```typescript
// oracle-updater.ts
class OracleUpdater {
  private priceFeeds = {
    BTC: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd",
    ETH: "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd",
  };
  
  async updatePrices() {
    setInterval(async () => {
      try {
        // 1. 외부 API에서 가격 가져오기
        const prices = await this.fetchPrices();
        
        // 2. Oracle UTXO 가져오기
        const oracleUtxo = await this.indexer.getOracleUtxo();
        const oracleDatum = this.parseOracleDatum(oracleUtxo.datum);
        
        // 3. 새로운 가격 데이터 구성
        const newPrices = prices.map(p => ({
          token: p.assetClass,
          price: this.toScaledPrice(p.price), // 1e30
          timestamp: Date.now(),
          confidence: 95, // 95% confidence
        }));
        
        // 4. 새로운 Oracle datum
        const newOracleDatum = {
          ...oracleDatum,
          prices: newPrices,
        };
        
        // 5. 트랜잭션 구성
        const tx = await this.lucid
          .newTx()
          .collectFrom([oracleUtxo], this.updatePricesRedeemer(newPrices))
          .payToContract(
            this.oracleAddress,
            { inline: Data.to(newOracleDatum) },
            oracleUtxo.assets
          )
          .addSigner(this.oracleAdmin) // Admin 서명 필요
          .complete();
        
        const signedTx = await tx.sign().complete();
        await signedTx.submit();
        
        console.log("Oracle prices updated");
      } catch (error) {
        console.error("Oracle update failed:", error);
      }
    }, 60000); // 1분마다
  }
  
  private async fetchPrices() {
    // Coingecko, Chainlink, Pyth 등에서 가격 가져오기
    // ...
  }
}
```

## 🎯 핵심 차이점 요약

### Ethereum: "명령형"
```
사용자 → "increasePosition 실행해!" → EVM → 알아서 처리
```

### Cardano: "선언형"
```
사용자 → 백엔드 → [UTXO 찾기 + 계산 + 트랜잭션 구성] 
      → Validator → "이게 맞나?" → ✅ or ❌
```

## ✅ Cardano 방식의 장점

1. **예측 가능성**
   - 제출 전에 모든 것을 로컬에서 검증
   - 실패하면 돈 안 잃음

2. **병렬 처리**
   - 다른 Position UTXO는 동시에 처리 가능
   - Ethereum은 하나씩만 처리

3. **투명성**
   - 트랜잭션에 모든 정보가 명시적으로 포함
   - 디버깅 쉬움

## ❌ Cardano 방식의 단점

1. **복잡한 백엔드**
   - UTXO 인덱싱 필요
   - 복잡한 트랜잭션 빌더
   - 많은 오프체인 인프라

2. **학습 곡선**
   - eUTXO 모델 이해 필요
   - Datum/Redeemer 개념
   - Lucid/Mesh 라이브러리 학습

3. **동시성 문제**
   - 여러 사용자가 같은 Vault UTXO를 동시에 소비하려 하면 충돌
   - UTXO contention 해결 필요 (queue, retry 등)

## 🛠️ 권장 스택

```
Frontend:    React + TypeScript
Wallet:      Lucid + Nami/Eternl
Backend:     Node.js + Express
Database:    PostgreSQL (UTXO 인덱싱)
Blockchain:  Blockfrost API
Monitoring:  Grafana + Prometheus
```

## 📚 다음 단계

1. **UTXO Indexer 구현** - 가장 중요!
2. **Transaction Builder 라이브러리** 작성
3. **Bot 서비스** (Liquidation, Oracle)
4. **Frontend 통합**
5. **테스트넷 배포 및 테스트**

Cardano는 복잡하지만, 제대로 구현하면 매우 강력합니다! 🚀

